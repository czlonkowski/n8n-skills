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
#                     tree (e.g. --ref main for a baseline); uses a temporary worktree
#   --budget USD      per-run spend cap, claude --max-budget-usd (default: 1.00)
#   --timeout SEC     per-run wall-clock limit (default: 600)
#   --out DIR         results directory (default: evaluations/build-tasks/results/<timestamp>)
#
# Each run gets its own directory with the prompt, the agent's transcript
# (transcript.json), stderr, the workflow.json it wrote, and score.json.
#
# Isolation:
#   - the plugin comes only from --plugin-dir; user settings and installed plugins are
#     not loaded (--setting-sources project,local), so an installed copy of this pack
#     can't leak into a baseline;
#   - MCP is n8n-mcp in docs-only mode (npx, no N8N_API_URL) under --strict-mcp-config,
#     so no live n8n instance is reachable and nothing gets deployed;
#   - the agent may only use Skill, Read, Write and the n8n-mcp docs/validation tools.
# Failures (auth, quota, timeout, no workflow.json) are recorded, never retried.
#
# Requires: claude (Claude Code CLI, signed in), node/npx, python3, git, perl.

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
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) CASES+=("$1"); shift ;;
  esac
done

for bin in claude npx python3 git perl; do
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

MCP_CONFIG="${OUT}/mcp.json"
cat > "${MCP_CONFIG}" <<'JSON'
{"mcpServers":{"n8n-mcp":{"command":"npx","args":["-y","n8n-mcp"],"env":{"MCP_MODE":"stdio","LOG_LEVEL":"error","DISABLE_CONSOLE_OUTPUT":"true"}}}}
JSON

TOOLS="Skill,Read,Write"
for t in get_node search_nodes validate_node validate_workflow tools_documentation search_templates get_template; do
  TOOLS+=",mcp__n8n-mcp__${t}"
done

echo "plugin: ${PLUGIN_DIR}${REF:+ (ref ${REF})}"
echo "model:  ${MODEL}   budget/run: \$${BUDGET}   timeout/run: ${TIMEOUT}s"
echo "out:    ${OUT}"
echo

TOTAL=0
PASSED=0
for case_file in "${CASES[@]}"; do
  case_file="$(cd "$(dirname "${case_file}")" && pwd)/$(basename "${case_file}")"
  id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "${case_file}")"
  task="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["task"])' "${case_file}")"
  n="${RUNS:-$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("runs", 3))' "${case_file}")}"
  case_pass=0
  for i in $(seq 1 "${n}"); do
    dir="${OUT}/${id}/run-${i}"
    mkdir -p "${dir}"
    cat > "${dir}/prompt.txt" <<EOF
${task}

Do not create, update or run anything on an n8n instance. When the workflow is final, write its JSON — an object with "name", "nodes" and "connections", in the shape n8n_create_workflow takes — to the file workflow.json in the current directory. Use the skills and n8n-mcp documentation tools as you normally would.
EOF
    (
      cd "${dir}" && perl -e 'alarm shift; exec @ARGV' "${TIMEOUT}" \
        claude -p "$(cat prompt.txt)" \
          --model "${MODEL}" \
          --plugin-dir "${PLUGIN_DIR}" \
          --setting-sources project,local \
          --strict-mcp-config --mcp-config "${MCP_CONFIG}" \
          --allowedTools "${TOOLS}" \
          --permission-mode dontAsk \
          --max-budget-usd "${BUDGET}" \
          --no-session-persistence \
          --output-format json \
          > transcript.json 2> stderr.log
    )
    status=$?
    python3 "${HERE}/score.py" "${case_file}" "${dir}/workflow.json" --json > "${dir}/score.json" 2>>"${dir}/stderr.log"
    if python3 -c 'import json,sys; sys.exit(0 if json.load(open(sys.argv[1]))["passed"] else 1)' "${dir}/score.json" 2>/dev/null; then
      verdict="PASS"; case_pass=$((case_pass + 1)); PASSED=$((PASSED + 1))
    else
      verdict="FAIL"
    fi
    TOTAL=$((TOTAL + 1))
    note=""
    [ "${status}" -ne 0 ] && note=" (claude exit ${status}; see stderr.log)"
    [ -f "${dir}/workflow.json" ] || note="${note} (no workflow.json)"
    echo "${verdict}  ${id}  run ${i}/${n}${note}"
    python3 -c '
import json,sys
d=json.load(open(sys.argv[1]))
for a in d.get("assertions", []):
    if not a["passed"]: print("        - %s: %s" % (a["assertion"], a["detail"]))
if d.get("error"): print("        - " + d["error"])' "${dir}/score.json" 2>/dev/null
  done
  echo "        ${id}: ${case_pass}/${n} runs passed"
done

echo
echo "TOTAL ${PASSED}/${TOTAL} runs passed  →  ${OUT}"
[ "${PASSED}" -eq "${TOTAL}" ]
