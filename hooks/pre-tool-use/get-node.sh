#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires before get_node. Two jobs:
#
# 1. Generic node-config reminder. Fires once per session (deduped by marker).
# 2. High-risk-node-specific reminders: Set, Code, Merge, splitInBatches
#    (Loop Over Items), DateTime, dataTable, and the LangChain Agent. These fire
#    EVERY time the agent looks up the node type, not just once per session. A
#    re-lookup of one of these is almost always the agent reconsidering ANOTHER
#    instance of the antipattern; once-per-session dedup would miss every
#    decision after the first.
#
# n8n-mcp's get_node takes a single SHORT-form node type, e.g. nodes-base.set or
# nodes-langchain.agent, in .tool_input.nodeType (not an array like the official
# get_node_types). The anchored regexes below match the short form.

set -uo pipefail

INPUT="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

SESSION_ID="$(echo "${INPUT}" | jq -r '.session_id // empty' 2>/dev/null)"
[ -z "${SESSION_ID}" ] && exit 0

NODE_TYPE="$(echo "${INPUT}" | jq -r '.tool_input.nodeType // empty' 2>/dev/null)"

STATE_DIR="${TMPDIR:-/tmp}/n8n-mcp-skills-state"
mkdir -p "${STATE_DIR}" 2>/dev/null || exit 0

has_marker() {
  [ -f "${STATE_DIR}/${SESSION_ID}-$1.loaded" ]
}

set_marker() {
  touch "${STATE_DIR}/${SESSION_ID}-$1.loaded" 2>/dev/null
}

matches() {
  echo "${NODE_TYPE}" | grep -qiE "$1"
}

WARNINGS=""

# Generic node-config reminder. Deduped: fires only on the first get_node call
# per session, since this reminder is general-purpose and re-firing adds nothing.
if ! has_marker "node-config"; then
  WARNINGS+="Before configuring this node, invoke the n8n-node-configuration skill via the Skill tool. Configuration is operation-aware: required fields depend on the resource/operation pair, and displayOptions control which fields are even visible. Never assume parameter names; confirm them against the get_node definition you're about to fetch. For interpreting any validation results afterward, n8n-validation-expert."
  set_marker "node-config"
fi

# High-risk-node warnings: NOT deduped. Each lookup fires the warning fresh.

if matches '(^|\.)set$'; then
  WARNINGS+="

[Set node detected]
Invoke the n8n-expression-syntax skill via the Skill tool. Edit Fields is right for a named step: a constant item, an error or return item, a payload object, or a value several nodes read. The antipattern is narrower: a Set whose only job is to re-map fields for the next node (before a Data Table insert, an email/Slack body, a Respond to Webhook, an HTTP body). Delete that one and put the expressions in the next node's own fields. Keep each field a short expression; a function body or several statements belongs in a Code node. See also n8n-node-configuration for field configuration."
fi

if matches '(^|\.)code$'; then
  WARNINGS+="

[Code node detected]
Check the job-to-node table in using-n8n-mcp-skills before writing a Code node: Filter, IF/Switch, Summarize, Aggregate, Split Out, Merge, Compare Datasets, Remove Duplicates, Sort + Limit, Date & Time, XML / HTML / Extract From File, HTTP Request pagination and Crypto cover most Code reaches. Code is for a closed list: loops or recursion, state across runs, parsing no node handles, libraries, heavy all-items work, or one short node replacing 4+ glue nodes. If Code stays, invoke n8n-code-javascript via the Skill tool and set the node's notes to \"Why Code: <native node considered> — <reason>\". Default to JavaScript; Python (n8n-code-python) only when the user asked; code an AI agent calls is a different runtime (n8n-code-tool)."
fi

if matches '(^|\.)merge$'; then
  WARNINGS+="

[Merge node detected]
STOP and invoke the n8n-node-configuration skill via the Skill tool. Two silent failure modes:

1. Merge defaults to 2 inputs. If 3+ sources converge here, set numberInputs explicitly to match (append, SQL, combine by position, choose branch; combine by fields is fixed at 2), or the third+ sources silently drop at runtime even though the connection lines are drawn.
2. The input index pairing is easy to wire backwards; off-by-one passes data from the wrong branch with no error. For wiring mistakes that survive into runtime, n8n-validation-expert."
fi

if matches '(^|\.)splitInBatches$'; then
  WARNINGS+="

[Loop Over Items (splitInBatches) detected]
STOP and invoke the n8n-code-javascript skill (loop patterns) and n8n-workflow-patterns (batch architecture) via the Skill tool.

First question: do you actually need this? Default per-item iteration probably handles your case WITHOUT a Loop Over Items node, just connect the source to the consumer. Loop Over Items is for rate limiting (process N at a time with a Wait between), chunked bulk API calls, per-batch error handling, or polling a long-running job. Output index trap: output 0 is DONE (fires once at the end), output 1 is LOOP (fires per batch). Easy to wire backwards."
fi

if matches '(^|\.)dateTime$'; then
  WARNINGS+="

[Date & Time node detected]
Both forms are fine. The Date & Time node suits a named step; set options.includeInputFields to true, or it outputs only the new date field. A Luxon one-liner in the consuming field needs no node:
  {{ DateTime.fromISO(\$('Source').item.json.created_at).toFormat('yyyy-MM-dd') }}
  {{ \$now.minus({ days: 7 }).toISO() }}
Take v2 operation and field names (addToDate, formatDate, getTimeBetweenDates) from get_node; v1 names differ. See n8n-node-configuration, and n8n-expression-syntax for Luxon."
fi

if matches '(^|\.)dataTable$'; then
  WARNINGS+="

[Data Table node detected]
STOP and invoke n8n-node-configuration and n8n-workflow-patterns via the Skill tool. Gotchas that catch people:

1. id, createdAt, updatedAt are SYSTEM-MANAGED. Don't declare them; they always exist and can be used in queries.
2. Column types are primitives only: string / number / boolean / date. No JSON/object/array column types. For nested data, use a string column with JSON.stringify() on write and JSON.parse() on read.
3. Map fields DIRECTLY in the Insert node's per-column slots. Do NOT add a Set node before the Data Table node to 'shape' the input.
For the n8n_manage_datatable tool itself (CRUD, filtering, dry-run), see n8n-mcp-tools-expert."
fi

if matches 'nodes-langchain\.agent$'; then
  WARNINGS+="

[AI Agent node detected]
Invoke the n8n-agents skill via the Skill tool. Tool names and descriptions ARE part of the prompt the model routes against — generic ones degrade tool selection. The model/memory/tools/output-parser sub-node slots, structured output (use autoFix), memory + sessionId continuity, and chat anti-loop filtering all have traps. Custom Code tools attached to the agent have their own runtime contract: n8n-code-tool."
fi

[ -z "${WARNINGS}" ] && exit 0

jq -n --arg ctx "${WARNINGS}" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
