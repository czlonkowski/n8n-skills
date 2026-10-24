#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires before validate_workflow / n8n_validate_workflow. Validation is the gate
# before activating; this is where the manual antipattern scan matters most,
# because validate_workflow does not catch any of the items below.
exec "$(dirname "$0")/_emit.sh" "validation-gate" \
"Before validating, run the antipattern scan node-by-node (invoke n8n-validation-expert and n8n-workflow-patterns via the Skill tool): a Set that only re-maps fields for the next node should be inlined there; each Code node should map to a native node from the job-to-node table in using-n8n-mcp-skills, or carry a \"Why Code:\" note naming its closed-list reason (same for HTTP Request: \"Why HTTP:\"); Merges with 3+ wires need numberInputs set explicitly; \$json.x in branchy workflows should be \$('Node').item.json.x. validate_workflow does not catch any of these; only the manual scan does. Validation passing means the JSON is well-formed, not that the workflow is correct."
