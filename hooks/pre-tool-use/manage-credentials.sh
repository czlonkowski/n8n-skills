#!/usr/bin/env bash
# Portions of this file are adapted from the n8n-io/skills plugin
# (https://github.com/n8n-io/skills), licensed under Apache License 2.0.
# Adapted for the community n8n-mcp MCP server. See /NOTICES.
#
# Fires before n8n_manage_credentials. Credentials hold live secrets, so this
# is the highest-stakes call: a misrouted write puts a secret on the wrong
# instance; on multi-instance accounts naming the instance is the safeguard. The
# reminder serves single-instance users too (credential discipline). One-shot.
exec "$(dirname "$0")/_emit.sh" "credentials" \
"Before a credential operation: invoke n8n-mcp-tools-expert via the Skill tool. Credentials hold live secrets — use the credential system and getSchema, never inline tokens into text fields. If this account has multiple n8n instances (the n8n_instances tool is present), ALSO invoke n8n-multi-instance and pass instance: \"<name>\" (from n8n_instances list) on the create/update/delete: an unnamed write goes to the connection's default, which other chats can move, and the server fail-closes only the AMBIGUOUS case (INSTANCE_AMBIGUOUS — retry with instance set). A named write to the wrong instance still writes the secret there, so check the name first. On older servers without the instance argument, verify current (n8n_instances list) immediately before the write."
