#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires before n8n_create_workflow. A new workflow means architecture, naming,
# and reuse decisions need to happen before the JSON lands.
#
# Two parts: a one-shot architecture reminder (once per session), and a scan of
# the payload for Code / HTTP Request nodes without a "Why Code:" / "Why HTTP:"
# note (once per node). Without jq only the one-shot reminder fires.

set -uo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ONE_SHOT="Before creating: invoke n8n-workflow-patterns (pick the right architecture — webhook / HTTP API / database / AI agent / scheduled / batch — name nodes for what they do, add sticky notes capturing the why) and n8n-subworkflows (search existing workflows with n8n_list_workflows and reuse a sub-workflow before duplicating logic) via the Skill tool. Pass skillsUsed if your server's create tool accepts it."

if ! command -v jq >/dev/null 2>&1; then
  exec "${HERE}/_emit.sh" "create-workflow" "${ONE_SHOT}"
fi

INPUT="$(cat)"
SESSION_ID="$(printf '%s' "${INPUT}" | jq -r '.session_id // empty' 2>/dev/null)"
[ -z "${SESSION_ID}" ] && exit 0

. "${HERE}/_why-note.sh" || exit 0

CTX="$(once "create-workflow" "${ONE_SHOT}")"
NOTE="$(why_note_reminder)"
[ -n "${CTX}" ] && [ -n "${NOTE}" ] && CTX+=$'\n\n'
emit_context "${CTX}${NOTE}"
exit 0
