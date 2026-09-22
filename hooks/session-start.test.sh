#!/usr/bin/env bash
# Regression test for the SessionStart hook's Python fallback.
#
# Reproduces the Windows failure mode: a `python3` that exists on PATH but
# fails when executed (simulating the Microsoft Store App Execution Alias
# stub), with a real, working `python` available as the fallback. Asserts
# the hook still succeeds by falling through to `python`.
#
# Does not copy or modify the system Python installation: it only locates
# whichever real interpreter is already on PATH and wraps it with a thin
# exec shim named "python" inside an isolated, throwaway PATH.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="${SCRIPT_DIR}/session-start.sh"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# --- Locate a real, working python on this machine (not copied) -------------
REAL_PYTHON="$(command -v python || command -v python3 || true)"
if [[ -z "${REAL_PYTHON}" ]] || ! "${REAL_PYTHON}" -c "import sys" >/dev/null 2>&1; then
  echo "SKIP: no working python interpreter found on this machine; cannot exercise the fallback path." >&2
  exit 0
fi

# --- Build an isolated, minimal PATH -----------------------------------------
FAKE_BIN="$(mktemp -d)"
TMP_HOME="$(mktemp -d)"
OUT="$(mktemp)"
ERR="$(mktemp)"
cleanup() { rm -rf "${FAKE_BIN}" "${TMP_HOME}" "${OUT}" "${ERR}"; }
trap cleanup EXIT

# A fake python3 that exists on PATH but fails when executed, reproducing the
# Windows App Execution Alias stub's behavior (non-zero exit, stderr message).
cat > "${FAKE_BIN}/python3" << 'STUB'
#!/usr/bin/env bash
echo "Python was not found; run without arguments to install from the Microsoft Store, or disable this shortcut from Settings > Apps > Advanced app settings > App execution aliases." >&2
exit 49
STUB
chmod +x "${FAKE_BIN}/python3"

# A thin exec wrapper named "python" pointing at the real interpreter found
# above. This is not a copy of the interpreter or its installation -- it's a
# few bytes of shell that delegates to the real binary's existing path.
cat > "${FAKE_BIN}/python" << WRAP
#!/usr/bin/env bash
exec "${REAL_PYTHON}" "\$@"
WRAP
chmod +x "${FAKE_BIN}/python"

# Minimal PATH: fake bin first (broken python3, working python shim), then
# just enough of the real PATH for the coreutils the hook needs (cat, mkdir,
# rm). Deliberately excludes jq so the test exercises the python fallback
# branch, not the jq branch.
CORE_DIRS="$(dirname "$(command -v cat)"):$(dirname "$(command -v mkdir)"):$(dirname "$(command -v rm)")"
TEST_PATH="${FAKE_BIN}:${CORE_DIRS}"

if PATH="${TEST_PATH}" command -v jq >/dev/null 2>&1; then
  fail "test setup invalid: jq is resolvable on the constructed PATH, so this wouldn't exercise the python fallback"
fi
if ! PATH="${TEST_PATH}" command -v python3 >/dev/null 2>&1; then
  fail "test setup invalid: fake python3 is not resolvable on the constructed PATH"
fi
if PATH="${TEST_PATH}" python3 -c "import sys" >/dev/null 2>&1; then
  fail "test setup invalid: fake python3 unexpectedly succeeded, so this wouldn't reproduce the broken-stub scenario"
fi
if ! PATH="${TEST_PATH}" command -v python >/dev/null 2>&1; then
  fail "test setup invalid: fallback python is not resolvable on the constructed PATH"
fi
if ! PATH="${TEST_PATH}" python -c "import sys" >/dev/null 2>&1; then
  fail "test setup invalid: fallback python did not execute successfully"
fi

# --- Run the actual hook under the simulated environment ---------------------
PATH="${TEST_PATH}" HOME="${TMP_HOME}" CLAUDE_PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)" \
  bash "${HOOK}" <<< '{"source":"startup","session_id":"test-session"}' \
  > "${OUT}" 2> "${ERR}"
EXIT_CODE=$?

# --- Assertions ----------------------------------------------------------------
[[ "${EXIT_CODE}" -eq 0 ]] || fail "exit code was ${EXIT_CODE}, expected 0. stderr: $(cat "${ERR}")"
[[ ! -s "${ERR}" ]] || fail "stderr was not empty: $(cat "${ERR}")"

"${REAL_PYTHON}" - "${OUT}" << 'PYEOF' || fail "JSON output assertions failed"
import json
import sys

with open(sys.argv[1]) as f:
    raw = f.read()

try:
    data = json.loads(raw)
except Exception as e:
    print("stdout is not valid JSON:", e)
    print("Raw output:", repr(raw))
    sys.exit(1)

hso = data.get("hookSpecificOutput")
if not isinstance(hso, dict):
    print("hookSpecificOutput missing or not an object:", repr(data))
    sys.exit(1)

if hso.get("hookEventName") != "SessionStart":
    print("hookEventName was", repr(hso.get("hookEventName")), "expected 'SessionStart'")
    sys.exit(1)

ctx = hso.get("additionalContext")
if not isinstance(ctx, str) or len(ctx) == 0:
    print("additionalContext missing or empty:", repr(ctx))
    sys.exit(1)
PYEOF

echo "PASS: session-start.sh correctly fell back from broken python3 to working python"
