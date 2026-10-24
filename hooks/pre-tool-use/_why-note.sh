#!/usr/bin/env bash
# Shared functions for the create/update PreToolUse hooks. Source it; don't run it.
#
# The callers set INPUT (the hook JSON from stdin) and SESSION_ID first, and only
# source this file when jq is available.
#
#   once <marker> <text>    print <text> the first time <marker> is seen this session
#   why_note_reminder       print a short reminder for Code / HTTP Request nodes in the
#                           payload whose notes lack "Why Code:" / "Why HTTP:", and for
#                           other nodes holding a function body inside {{ }}
#   emit_context <text>     print the PreToolUse JSON, or nothing when <text> is empty
#
# Everything fails open: a parse error prints nothing and never blocks the tool call.

STATE_DIR="${TMPDIR:-/tmp}/n8n-mcp-skills-state"
mkdir -p "${STATE_DIR}" 2>/dev/null || true

once() {
  local marker="${STATE_DIR}/${SESSION_ID}-$1.loaded"
  [ -f "${marker}" ] && return 0
  touch "${marker}" 2>/dev/null || return 0
  printf '%s' "$2"
}

# Nodes come from a full payload (create / full update: .nodes) and from
# addNode operations (partial update). A node whose note is added by an
# updateNode operation in the same call counts as covered.
why_note_reminder() {
  local rows wf_key code_names="" http_names="" expr_names="" kind name hash marker out=""

  rows="$(printf '%s' "${INPUT}" | jq -r '
    (.tool_input // {}) as $in
    | ([ ($in.operations // [])[]
         | select(type == "object" and .type == "updateNode")
         | select(((.updates.notes // "") | tostring) | test("Why (Code|HTTP):"; "i"))
         | (.nodeName // .name // empty) ]) as $noted
    | (($in.nodes // $in.workflow.nodes // [])
       + [ ($in.operations // [])[]
           | select(type == "object" and .type == "addNode") | .node ])
    | .[]
    | select(type == "object")
    | (.name // "unnamed") as $name
    | (
        ( (if .type == "n8n-nodes-base.code" then "Code"
           elif .type == "n8n-nodes-base.httpRequest" then "HTTP"
           else empty end) as $kind
          | select((((.notes // "") | tostring) | test("Why " + $kind + ":"; "i")) | not)
          | select(($noted | index($name)) | not)
          | $kind ),
        # A function body (IIFE) inside an expression in a non-Code node is code (D2).
        ( select((.type // "") | test("(\\.code|\\.function|\\.functionItem|\\.toolCode)$") | not)
          | select([(.parameters // {}) | .. | strings
                    | select(test("\\(\\s*\\(\\s*\\)\\s*=>|\\(\\s*function\\s*\\("))] | length > 0)
          | "Expr" )
      )
    | [., $name] | @tsv
  ' 2>/dev/null)" || return 0
  [ -z "${rows}" ] && return 0

  wf_key="$(printf '%s' "${INPUT}" | jq -r '.tool_input.id // .tool_input.name // "new"' 2>/dev/null)"

  while IFS=$'\t' read -r kind name; do
    [ -z "${kind}" ] && continue
    # One reminder per node per session.
    hash="$(printf '%s|%s|%s' "${wf_key}" "${kind}" "${name}" | cksum | cut -d' ' -f1)"
    marker="${STATE_DIR}/${SESSION_ID}-why-${hash}.loaded"
    [ -f "${marker}" ] && continue
    touch "${marker}" 2>/dev/null || continue
    case "${kind}" in
      Code) code_names+="${code_names:+, }\"${name}\"" ;;
      HTTP) http_names+="${http_names:+, }\"${name}\"" ;;
      Expr) expr_names+="${expr_names:+, }\"${name}\"" ;;
    esac
  done <<< "${rows}"

  if [ -n "${code_names}" ]; then
    out+="Code node(s) without a \"Why Code:\" note: ${code_names}. Check the job-to-node table in using-n8n-mcp-skills first; if Code stays, set notes to \"Why Code: <native node considered> — <reason>\"."
  fi
  if [ -n "${http_names}" ]; then
    out+="${out:+ }HTTP Request node(s) without a \"Why HTTP:\" note: ${http_names}. Check search_nodes for the service's own node first; if HTTP stays, set notes to \"Why HTTP: <node considered> — <reason>\"."
  fi
  if [ -n "${expr_names}" ]; then
    out+="${out:+ }Function body inside {{ }} in: ${expr_names}. Several statements in an expression are code: use a native node or short expressions, or move the logic to a Code node with a \"Why Code:\" note."
  fi
  printf '%s' "${out}"
}

emit_context() {
  [ -z "$1" ] && return 0
  jq -n --arg ctx "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $ctx
    }
  }'
}
