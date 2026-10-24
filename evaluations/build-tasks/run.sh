#!/usr/bin/env bash
# Run the build-task evals: ask an agent to build each case's workflow with this
# plugin loaded, then score the workflow JSON it writes. Manual use only — every
# run is a real, billed agent session.
#
#   evaluations/build-tasks/run.sh [options] [case.json ...]
#
#   --runs N          runs per case (default: the case's "runs", usually 3)
#   --model M         model alias or id passed to claude (default: sonnet)
#   --ref GIT_REF     load the plugin from this git ref instead of the working
#                     tree (e.g. the commit before a change, for a baseline);
#                     uses a temporary worktree
#   --budget USD      per-run spend cap, claude --max-budget-usd (default: 1.00)
#   --timeout SEC     per-run wall-clock limit (default: 600)
#   --out DIR         results directory (default: evaluations/build-tasks/results/<timestamp>)
#
# N8N_MCP_VERSION=2.97.0 pins the n8n-mcp version (default: the latest on npm).
#
# Each run's directory holds the prompt, the agent's event stream (transcript.jsonl),
# stderr, the workflow.json it wrote, run.json (what loaded, cost, denials) and score.json.
#
# Isolation:
#   - the agent works in a fresh temp directory outside any repository, so no project
#     CLAUDE.md, .claude/ settings or project skills are picked up (this repository has
#     its own .claude/ folder); artifacts are copied into the results directory after;
#   - the plugin comes only from --plugin-dir; user settings and installed plugins are
#     not loaded (--setting-sources project,local), so an installed copy of this pack
#     can't leak into a baseline;
#   - MCP is n8n-mcp in docs-only mode (npx, no N8N_API_URL) under --strict-mcp-config,
#     so no live n8n instance is reachable and nothing gets deployed;
#   - the agent may only use Skill, Read, Write and the n8n-mcp docs/validation tools.
# A run where the plugin or n8n-mcp didn't load, or the session errored, is reported as
# INFRA and left out of the pass rate. Nothing is retried.
#
# Requires: claude (Claude Code CLI, signed in), node/npm/npx, python3, git, perl.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "${HERE}/../.." && pwd)"
RUNS=""
MODEL="sonnet"
REF=""
BUDGET="1.00"
TIMEOUT=600
OUT=""
CASES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --runs) RUNS="$2"; shift 2 ;;
    --model) MODEL="$2"; shift 2 ;;
    --ref) REF="$2"; shift 2 ;;
    --budget) BUDGET="$2"; shift 2 ;;
    --timeout) TIMEOUT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    -h|--help) sed -n '2,35p' "$0"; exit 0 ;;
    *) CASES+=("$1"); shift ;;
  esac
done

for bin in claude npm npx python3 git perl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "missing: $bin" >&2; exit 2; }
done

if [ ${#CASES[@]} -eq 0 ]; then
  for f in "${HERE}"/cases/*.json; do CASES+=("$f"); done
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="${OUT:-${HERE}/results/${STAMP}${REF:+-${REF//\//_}}}"
mkdir -p "${OUT}"
OUT="$(cd "${OUT}" && pwd)"

PLUGIN_DIR="${REPO}"
WORKTREE=""
if [ -n "${REF}" ]; then
  WORKTREE="$(mktemp -d)/plugin"
  git -C "${REPO}" worktree add --detach "${WORKTREE}" "${REF}" >/dev/null 2>&1 \
    || { echo "could not check out ${REF}" >&2; exit 2; }
  PLUGIN_DIR="${WORKTREE}"
  trap 'git -C "${REPO}" worktree remove --force "${WORKTREE}" >/dev/null 2>&1' EXIT
fi
PLUGIN_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' "${PLUGIN_DIR}/.claude-plugin/plugin.json" 2>/dev/null)"

# Pin n8n-mcp to one version for every run of this invocation (the latest on npm
# unless N8N_MCP_VERSION is set), so both arms of a comparison hit the same server, and
# install it into the npx cache once so a slow first download can't time out the MCP
# handshake of the first run.
MCP_VERSION="${N8N_MCP_VERSION:-$(npm view n8n-mcp version 2>/dev/null)}"
MCP_PKG="n8n-mcp${MCP_VERSION:+@${MCP_VERSION}}"
npm exec --yes --package="${MCP_PKG}" -- node -e 0 >/dev/null 2>&1 \
  || echo "warning: could not pre-install ${MCP_PKG}; runs may report INFRA" >&2

MCP_CONFIG="${OUT}/mcp.json"
cat > "${MCP_CONFIG}" <<JSON
{"mcpServers":{"n8n-mcp":{"command":"npx","args":["-y","${MCP_PKG}"],"env":{"MCP_MODE":"stdio","LOG_LEVEL":"error","DISABLE_CONSOLE_OUTPUT":"true"}}}}
JSON

TOOLS="Skill,Read,Write"
for t in get_node search_nodes validate_node validate_workflow tools_documentation search_templates get_template; do
  TOOLS+=",mcp__n8n-mcp__${t}"
done

echo "plugin: ${PLUGIN_DIR} (v${PLUGIN_VERSION}${REF:+, ref ${REF}})"
echo "n8n-mcp: ${MCP_PKG}"
echo "model:  ${MODEL}   budget/run: \$${BUDGET}   timeout/run: ${TIMEOUT}s"
echo "out:    ${OUT}"
echo

PASSED=0
FAILED=0
INFRA=0
COST="0"
for case_file in "${CASES[@]}"; do
  case_file="$(cd "$(dirname "${case_file}")" && pwd)/$(basename "${case_file}")"
  id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "${case_file}")"
  task="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["task"])' "${case_file}")"
  n="${RUNS:-$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("runs", 3))' "${case_file}")}"
  case_pass=0
  case_scored=0
  for i in $(seq 1 "${n}"); do
    dir="${OUT}/${id}/run-${i}"
    work="$(mktemp -d)"
    mkdir -p "${dir}"
    cat > "${dir}/prompt.txt" <<EOF
${task}

Do not create, update or run anything on an n8n instance. When the workflow is final, write its JSON — an object with "name", "nodes" and "connections", in the shape n8n_create_workflow takes — to the file workflow.json in the current directory. Use the skills and n8n-mcp documentation tools as you normally would.
EOF
    (
      cd "${work}" && MCP_TIMEOUT=120000 perl -e 'alarm shift; exec @ARGV' "${TIMEOUT}" \
        claude -p "$(cat "${dir}/prompt.txt")" \
          --model "${MODEL}" \
          --plugin-dir "${PLUGIN_DIR}" \
          --setting-sources project,local \
          --strict-mcp-config --mcp-config "${MCP_CONFIG}" \
          --allowedTools "${TOOLS}" \
          --permission-mode dontAsk \
          --max-budget-usd "${BUDGET}" \
          --no-session-persistence \
          --output-format stream-json --verbose \
          > "${dir}/transcript.jsonl" 2> "${dir}/stderr.log"
    )
    status=$?
    [ -f "${work}/workflow.json" ] && cp "${work}/workflow.json" "${dir}/workflow.json"
    rm -rf "${work}"

    # What actually loaded, what it cost, and whether the run is usable at all.
    python3 - "${dir}" "${PLUGIN_DIR}" "${status}" <<'PY'
import json, sys
d, plugin_dir, status = sys.argv[1], sys.argv[2], int(sys.argv[3])
info = {"exit": status, "plugin_loaded": False, "mcp_status": None, "cost_usd": 0.0,
        "is_error": None, "denials": [], "infra": []}
try:
    for line in open(d + "/transcript.jsonl"):
        try:
            e = json.loads(line)
        except ValueError:
            continue
        if e.get("type") == "system" and e.get("subtype") == "init":
            info["plugin_loaded"] = any(p.get("path") == plugin_dir for p in e.get("plugins", []))
            for s in e.get("mcp_servers", []):
                if s.get("name") == "n8n-mcp":
                    info["mcp_status"] = s.get("status")
        if e.get("type") == "result":
            info["cost_usd"] = e.get("total_cost_usd") or 0.0
            info["is_error"] = e.get("is_error")
            info["denials"] = [x.get("tool_name") for x in e.get("permission_denials", [])]
except OSError:
    pass
if not info["plugin_loaded"]:
    info["infra"].append("plugin not loaded from " + plugin_dir)
if info["mcp_status"] != "connected":
    info["infra"].append("n8n-mcp " + str(info["mcp_status"] or "missing"))
if info["is_error"] is not False:
    info["infra"].append("session error or no result (exit %d)" % status)
if "Write" in info["denials"]:
    info["infra"].append("Write denied")
json.dump(info, open(d + "/run.json", "w"), indent=1)
PY
    python3 "${HERE}/score.py" "${case_file}" "${dir}/workflow.json" --json > "${dir}/score.json" 2>>"${dir}/stderr.log"
    run_cost="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["cost_usd"])' "${dir}/run.json" 2>/dev/null || echo 0)"
    COST="$(python3 -c 'import sys; print(round(float(sys.argv[1]) + float(sys.argv[2]), 4))' "${COST}" "${run_cost}")"
    infra="$(python3 -c 'import json,sys; print("; ".join(json.load(open(sys.argv[1]))["infra"]))' "${dir}/run.json" 2>/dev/null)"
    if [ -n "${infra}" ]; then
      verdict="INFRA"; INFRA=$((INFRA + 1))
    elif python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))["passed"] else 1)' "${dir}/score.json" 2>/dev/null; then
      verdict="PASS"; PASSED=$((PASSED + 1)); case_pass=$((case_pass + 1)); case_scored=$((case_scored + 1))
    else
      verdict="FAIL"; FAILED=$((FAILED + 1)); case_scored=$((case_scored + 1))
    fi
    echo "${verdict}  ${id}  run ${i}/${n}  \$${run_cost}${infra:+  (${infra})}"
    if [ "${verdict}" = "FAIL" ]; then
      python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
for a in d.get("assertions", []):
    if not a["passed"]: print("        - %s: %s" % (a["assertion"], a["detail"]))
if d.get("error"): print("        - " + d["error"])' "${dir}/score.json" 2>/dev/null
    fi
  done
  echo "        ${id}: ${case_pass}/${case_scored} scored runs passed"
done

echo
echo "TOTAL ${PASSED}/$((PASSED + FAILED)) scored runs passed, ${INFRA} INFRA, cost \$${COST}  →  ${OUT}"
[ "${FAILED}" -eq 0 ] && [ "${INFRA}" -eq 0 ]
