#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires AFTER validate_workflow. Validation passing is necessary, not sufficient.
#
# n8n-mcp's validate_workflow takes the FULL workflow JSON, so we parse the node
# types out of .tool_input.workflow.nodes[].type (Claude) or
# .toolInput.workflow.nodes[].type (Grok) — LONG form, e.g.
# "n8n-nodes-base.set") and route to the relevant skills. This is more robust
# than grepping source code. Fires every call (no dedup).
#
# Routes: sub-workflow trigger -> n8n-subworkflows; LangChain agent -> n8n-agents.

set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat)"

# Node types from the validated workflow JSON. Fall back to a flattened nodes
# array in case a server nests differently.
NODE_TYPES="$(echo "${INPUT}" | jq -r '
  (.tool_input.workflow.nodes // .toolInput.workflow.nodes // .tool_input.nodes // .toolInput.nodes // [])
  | map(.type // empty) | .[]
' 2>/dev/null)"

# --- No node data (by-id validation or empty payload): generic gate ----------
if [ -z "${NODE_TYPES//[[:space:]]/}" ]; then
  jq -n '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:
    "[validate_workflow returned. Validation is necessary, not sufficient.] No node JSON was available to analyze. If this workflow is non-trivial, invoke n8n-validation-expert and n8n-workflow-patterns via the Skill tool and run the antipattern scan before activating."}}'
  exit 0
fi

NODE_COUNT="$(printf '%s\n' "${NODE_TYPES}" | grep -c . 2>/dev/null || echo 0)"

has_type()   { printf '%s\n' "${NODE_TYPES}" | grep -qxF "$1"; }
has_suffix() { printf '%s\n' "${NODE_TYPES}" | grep -qiE "$1"; }

HAS_SET=0;           has_type "n8n-nodes-base.set"                   && HAS_SET=1
HAS_CODE=0;          has_type "n8n-nodes-base.code"                  && HAS_CODE=1
HAS_MERGE=0;         has_type "n8n-nodes-base.merge"                 && HAS_MERGE=1
HAS_LOOP=0;          has_type "n8n-nodes-base.splitInBatches"        && HAS_LOOP=1
HAS_DATETIME=0;      has_type "n8n-nodes-base.dateTime"              && HAS_DATETIME=1
HAS_DATATABLE=0;     has_type "n8n-nodes-base.dataTable"             && HAS_DATATABLE=1
HAS_SUBWF_TRIGGER=0; has_type "n8n-nodes-base.executeWorkflowTrigger" && HAS_SUBWF_TRIGGER=1
HAS_WEBHOOK=0;       has_type "n8n-nodes-base.webhook"               && HAS_WEBHOOK=1
HAS_HTTP=0;          has_type "n8n-nodes-base.httpRequest"           && HAS_HTTP=1
HAS_RESPOND=0;       has_type "n8n-nodes-base.respondToWebhook"      && HAS_RESPOND=1
HAS_SCHEDULE=0;      has_type "n8n-nodes-base.scheduleTrigger"       && HAS_SCHEDULE=1
HAS_AGENT=0;         has_suffix 'nodes-langchain\.agent$'           && HAS_AGENT=1
HAS_CHAT_TRIGGER=0;  has_suffix 'langchain\.chatTrigger$'           && HAS_CHAT_TRIGGER=1
HAS_DOLLAR_JSON=0;   echo "${INPUT}" | jq -r '..|strings' 2>/dev/null | grep -qE '\$json\.' && HAS_DOLLAR_JSON=1

# Detected summary line
DETECTED=""
[ $HAS_SET -eq 1 ]           && DETECTED+=" Set"
[ $HAS_CODE -eq 1 ]          && DETECTED+=" Code"
[ $HAS_MERGE -eq 1 ]         && DETECTED+=" Merge"
[ $HAS_LOOP -eq 1 ]          && DETECTED+=" Loop"
[ $HAS_DATETIME -eq 1 ]      && DETECTED+=" DateTime"
[ $HAS_SUBWF_TRIGGER -eq 1 ] && DETECTED+=" SubWorkflowTrigger"
[ $HAS_DATATABLE -eq 1 ]     && DETECTED+=" DataTable"
[ $HAS_AGENT -eq 1 ]         && DETECTED+=" Agent"
[ $HAS_WEBHOOK -eq 1 ]       && DETECTED+=" Webhook"
[ $HAS_HTTP -eq 1 ]          && DETECTED+=" HttpRequest"
[ $HAS_RESPOND -eq 1 ]       && DETECTED+=" RespondToWebhook"
[ $HAS_SCHEDULE -eq 1 ]      && DETECTED+=" Schedule"
[ -z "${DETECTED}" ] && DETECTED=" (none of the high-risk node types)"

# Consolidated n8n-expression-syntax reasons
EXPR_REASONS=""
[ $HAS_SET -eq 1 ]      && EXPR_REASONS+="Set inline antipattern, "
[ $HAS_DATETIME -eq 1 ] && EXPR_REASONS+="DateTime -> Luxon, "
[ $HAS_DOLLAR_JSON -eq 1 ] && EXPR_REASONS+="\$json refs in branchy flow, "
EXPR_REASONS="${EXPR_REASONS%, }"

SUGGESTIONS=""
[ $HAS_MERGE -eq 1 ]      && SUGGESTIONS+="
- n8n-node-configuration (Merge: numberOfInputs vs wire count, input index off-by-one)"
[ -n "${EXPR_REASONS}" ] && SUGGESTIONS+="
- n8n-expression-syntax (${EXPR_REASONS})"
[ $HAS_CODE -eq 1 ]      && SUGGESTIONS+="
- n8n-code-javascript (Code present: review against expression / Edit Fields alternatives; Python -> n8n-code-python; agent tool -> n8n-code-tool)"
{ [ $HAS_LOOP -eq 1 ] || [ $HAS_HTTP -eq 1 ]; } && SUGGESTIONS+="
- n8n-code-javascript + n8n-workflow-patterns (Loop Over Items / HTTP pagination & batching)"
[ $HAS_SUBWF_TRIGGER -eq 1 ] && SUGGESTIONS+="
- n8n-subworkflows (sub-workflow trigger: Define-Below input mode + return-shape rules)"
[ $HAS_DATATABLE -eq 1 ] && SUGGESTIONS+="
- n8n-node-configuration + n8n-workflow-patterns (Data Table: system columns, primitive-only types, map-in-Insert rule)"
{ [ $HAS_HTTP -eq 1 ] || [ $HAS_WEBHOOK -eq 1 ] || [ $HAS_RESPOND -eq 1 ]; } && SUGGESTIONS+="
- n8n-mcp-tools-expert (auth surface present: use the credential system, never inline tokens)"
{ [ $HAS_WEBHOOK -eq 1 ] || [ $HAS_RESPOND -eq 1 ] || [ $HAS_SCHEDULE -eq 1 ] || [ $HAS_CHAT_TRIGGER -eq 1 ] || [ $HAS_AGENT -eq 1 ]; } && SUGGESTIONS+="
- n8n-error-handling (unattended / webhook / agent workflow: wire an error branch on every fallible node; 4xx/5xx response shapes)"
[ "${NODE_COUNT}" -gt 6 ] && SUGGESTIONS+="
- n8n-workflow-patterns (>6 nodes: architecture review, sticky notes, naming)"
[ $HAS_AGENT -eq 1 ]     && SUGGESTIONS+="
- n8n-agents (LangChain Agent: tool names/descriptions are part of the prompt; structured output + autoFix; memory/sessionId)"

if [ -z "${SUGGESTIONS}" ]; then
  WARNINGS="[validate_workflow returned. Validation is necessary, not sufficient.]
Workflow analyzed: ${NODE_COUNT} node(s); detected:${DETECTED}.

No high-risk patterns surfaced. If anything here is non-trivial, invoke n8n-validation-expert and n8n-workflow-patterns via the Skill tool and run the antipattern scan before activating."
else
  WARNINGS="[validate_workflow returned. Validation is necessary, not sufficient.]
Workflow analyzed: ${NODE_COUNT} node(s); detected:${DETECTED}.

If any of these skills are not already in your context, invoke them via the Skill tool:${SUGGESTIONS}

This is the gate. Walk these BEFORE activating the workflow. Validation passing means the JSON is well-formed; it does NOT mean the workflow is correct."
fi

jq -n --arg ctx "${WARNINGS}" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
