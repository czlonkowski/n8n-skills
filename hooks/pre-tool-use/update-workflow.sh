#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires before n8n_update_partial_workflow / n8n_update_full_workflow. Updates
# touch connections, where the most subtle bugs live (silently dropped wires,
# Merge index off-by-one).
#
# Two parts: a one-shot connections reminder (once per session), and a scan of
# full-update nodes and addNode operations for Code / HTTP Request nodes without
# a "Why Code:" / "Why HTTP:" note (once per node). Without jq only the one-shot
# reminder fires.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ONE_SHOT="Before updating: after applying the operations, verify the connections object with n8n_get_workflow. validate_workflow does not catch every multi-input wiring trap. For Merge node specifics (numberInputs, input index off-by-one) see n8n-node-configuration; for wiring that survives into runtime see n8n-validation-expert; for per-node error outputs (onError + wiring main[1]) see n8n-error-handling. Invoke them via the Skill tool."

if ! command -v jq >/dev/null 2>&1; then
  exec "${HERE}/_emit.sh" "connections" "${ONE_SHOT}"
fi

INPUT="$(cat)"
SESSION_ID="$(printf '%s' "${INPUT}" | jq -r '.session_id // empty' 2>/dev/null)"
[ -z "${SESSION_ID}" ] && exit 0

. "${HERE}/_why-note.sh" || exit 0

CTX="$(once "connections" "${ONE_SHOT}")"
NOTE="$(why_note_reminder)"
[ -n "${CTX}" ] && [ -n "${NOTE}" ] && CTX+=$'\n\n'
emit_context "${CTX}${NOTE}"
exit 0
