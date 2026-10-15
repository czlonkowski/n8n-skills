#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires before n8n_instances (list/switch). This tool only exists on
# multi-instance accounts. Every other n8n tool takes an optional per-call
# `instance` name; without it a call routes to the connection's default, which
# other chats on the same connection can move, with no error on a misroute.
# One-shot per session — the rules are a mental model, not a per-call checklist.
exec "$(dirname "$0")/_emit.sh" "multi-instance" \
"Before listing or switching instances: invoke the n8n-multi-instance skill via the Skill tool. Prefer naming the target on each call — every n8n tool takes an optional instance: \"<name>\" (a name from n8n_instances list) that routes only that call and changes nothing for anyone else. switch only sets the DEFAULT for unnamed calls, and on hosted connectors (claude.ai) that default is shared by every chat on the connection, so a switch moves other agents too. A wrong target is usually silent. Name the instance on credential writes (a named write is never INSTANCE_AMBIGUOUS). INSTANCE_NOT_FOUND lists the valid names — pick one, never drop the argument. An unexpected NOT_FOUND is almost always a wrong-instance misroute, not a deletion: retry with the right instance, do not recreate. If the tool schemas have no instance property (older server), switch in its OWN turn and verify current before credential writes."
