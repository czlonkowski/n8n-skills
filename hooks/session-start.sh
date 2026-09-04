#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# SessionStart hook for n8n-mcp-skills.
# Loads the meta-skill (using-n8n-mcp-skills) into every session via additionalContext.
# Re-fires on resume/clear/compact so the protocol survives compaction.
#
# On `clear` and `compact`, also wipes the PreToolUse hook markers for this
# session so the per-node-type warnings can fire again. The agent's memory
# of those warnings is gone after a clear/compact, so the markers shouldn't
# keep them silent.
#
# Fails silently and never blocks session startup.

set -uo pipefail

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
META_SKILL="${PLUGIN_ROOT}/skills/using-n8n-mcp-skills/SKILL.md"
CACHE_DIR="${HOME}/.cache/n8n-mcp-skills"
mkdir -p "${CACHE_DIR}" 2>/dev/null || true

INPUT="$(cat)"

# --- Reset PreToolUse markers on clear/compact -------------------------------
#
# After /clear or /compact, the agent has lost the additionalContext that the
# PreToolUse hooks injected earlier in the session. Without wiping markers,
# the per-node warnings stay silent for the rest of the session even though
# the agent no longer remembers them.

if command -v jq >/dev/null 2>&1; then
  SOURCE="$(echo "${INPUT}" | jq -r '.source // empty' 2>/dev/null)"
  SESSION_ID="$(echo "${INPUT}" | jq -r '.session_id // .sessionId // empty' 2>/dev/null)"

  if [[ "${SOURCE}" == "clear" || "${SOURCE}" == "compact" ]] && [[ -n "${SESSION_ID}" ]]; then
    STATE_DIR="${TMPDIR:-/tmp}/n8n-mcp-skills-state"
    rm -f "${STATE_DIR}/${SESSION_ID}-"*.loaded 2>/dev/null || true
  fi
fi

# --- Build additionalContext --------------------------------------------------

if [[ ! -r "${META_SKILL}" ]]; then
  # Skill missing or unreadable. Fail open with no context, don't break session.
  exit 0
fi

SKILL_BODY="$(cat "${META_SKILL}")"

ADDITIONAL_CONTEXT="${SKILL_BODY}"

# --- Emit hook output ---------------------------------------------------------

# jq is the safe way to escape arbitrary text into JSON. Fall back to python3
# if jq isn't installed (rare on macOS, possible on minimal Linux).
if command -v jq >/dev/null 2>&1; then
  jq -n --arg ctx "${ADDITIONAL_CONTEXT}" '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: $ctx
    }
  }'
elif command -v python3 >/dev/null 2>&1; then
  python3 -c '
import json, sys
ctx = sys.stdin.read()
print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ctx
  }
}))
' <<< "${ADDITIONAL_CONTEXT}"
else
  # No JSON encoder available, skip injection rather than emit malformed JSON.
  exit 0
fi
