#!/usr/bin/env python3
"""Hook harness compatibility: Claude snake_case + mcp__ vs Grok camelCase + server__tool."""

from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import unittest
import uuid
from pathlib import Path

HOOKS_DIR = Path(__file__).resolve().parent.parent
PLUGIN_ROOT = HOOKS_DIR.parent
HOOKS_JSON = HOOKS_DIR / "hooks.json"
EMIT = HOOKS_DIR / "pre-tool-use" / "_emit.sh"
GET_NODE = HOOKS_DIR / "pre-tool-use" / "get-node.sh"
SESSION_START = HOOKS_DIR / "session-start.sh"
POST_VALIDATE = HOOKS_DIR / "post-tool-use" / "validate-workflow.sh"


def run_script(script: Path, payload: dict, extra_args: list[str] | None = None, tmpdir: str | None = None) -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["CLAUDE_PLUGIN_ROOT"] = str(PLUGIN_ROOT)
    if tmpdir:
        env["TMPDIR"] = tmpdir
    return subprocess.run(
        ["bash", str(script), *(extra_args or [])],
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        env=env,
        cwd=str(PLUGIN_ROOT),
        check=False,
    )


def context_text(stdout: str) -> str:
    stdout = stdout.strip()
    if not stdout:
        return ""
    data = json.loads(stdout)
    return data.get("hookSpecificOutput", {}).get("additionalContext", "")


def matchers_for(event: str) -> list[str]:
    spec = json.loads(HOOKS_JSON.read_text())
    return [block["matcher"] for block in spec["hooks"][event]]


def any_match(event: str, tool_name: str) -> bool:
    return any(re.search(pattern, tool_name) for pattern in matchers_for(event))


class MatcherTests(unittest.TestCase):
    """PreToolUse matchers must fire for Claude mcp__ names and Grok server__tool names."""

    CLAUDE = {
        "get_node": "mcp__n8n-mcp__get_node",
        "create": "mcp__n8n-mcp__n8n_create_workflow",
        "update_partial": "mcp__n8n-mcp__n8n_update_partial_workflow",
        "update_full": "mcp__n8n-mcp__n8n_update_full_workflow",
        "validate": "mcp__n8n-mcp__validate_workflow",
        "n8n_validate": "mcp__n8n-mcp__n8n_validate_workflow",
        "test": "mcp__n8n-mcp__n8n_test_workflow",
        "instances": "mcp__n8n-mcp__n8n_instances",
        "credentials": "mcp__n8n-mcp__n8n_manage_credentials",
    }
    GROK = {
        "get_node": "n8n-mcp__get_node",
        "create": "n8n-mcp__n8n_create_workflow",
        "update_partial": "n8n-mcp__n8n_update_partial_workflow",
        "update_full": "n8n-mcp__n8n_update_full_workflow",
        "validate": "n8n-mcp__validate_workflow",
        "n8n_validate": "n8n-mcp__n8n_validate_workflow",
        "test": "n8n-mcp__n8n_test_workflow",
        "instances": "n8n-mcp__n8n_instances",
        "credentials": "n8n-mcp__n8n_manage_credentials",
    }

    def test_claude_mcp_names_still_match_pretooluse(self) -> None:
        for name in self.CLAUDE.values():
            self.assertTrue(any_match("PreToolUse", name), msg=name)

    def test_grok_server_tool_names_match_pretooluse(self) -> None:
        for name in self.GROK.values():
            self.assertTrue(any_match("PreToolUse", name), msg=name)

    def test_claude_validate_matches_posttooluse(self) -> None:
        self.assertTrue(any_match("PostToolUse", self.CLAUDE["validate"]))

    def test_grok_validate_matches_posttooluse(self) -> None:
        self.assertTrue(any_match("PostToolUse", self.GROK["validate"]))

    def test_unrelated_tools_do_not_match(self) -> None:
        for name in ("run_terminal_command", "use_tool", "forget_node", "n8n-mcp__search_nodes"):
            self.assertFalse(any_match("PreToolUse", name), msg=name)


class EmitTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmpdir = self._tmp.name

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_claude_session_id_emits_once(self) -> None:
        sid = f"claude-{uuid.uuid4()}"
        payload = {"session_id": sid}
        first = run_script(EMIT, payload, extra_args=["lifecycle", "load n8n-workflow-patterns"], tmpdir=self.tmpdir)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertIn("n8n-workflow-patterns", context_text(first.stdout))
        second = run_script(EMIT, payload, extra_args=["lifecycle", "load n8n-workflow-patterns"], tmpdir=self.tmpdir)
        self.assertEqual(second.stdout.strip(), "")

    def test_grok_sessionId_emits_once(self) -> None:
        sid = f"grok-{uuid.uuid4()}"
        payload = {"sessionId": sid, "hookEventName": "pre_tool_use"}
        first = run_script(EMIT, payload, extra_args=["lifecycle", "load n8n-workflow-patterns"], tmpdir=self.tmpdir)
        self.assertEqual(first.returncode, 0, first.stderr)
        self.assertIn("n8n-workflow-patterns", context_text(first.stdout))
        second = run_script(EMIT, payload, extra_args=["lifecycle", "load n8n-workflow-patterns"], tmpdir=self.tmpdir)
        self.assertEqual(second.stdout.strip(), "")


class GetNodeTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmpdir = self._tmp.name

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_claude_tool_input_set_node(self) -> None:
        payload = {
            "session_id": f"claude-set-{uuid.uuid4()}",
            "tool_input": {"nodeType": "nodes-base.set"},
        }
        result = run_script(GET_NODE, payload, tmpdir=self.tmpdir)
        self.assertEqual(result.returncode, 0, result.stderr)
        ctx = context_text(result.stdout)
        self.assertIn("Set node detected", ctx)
        self.assertIn("n8n-expression-syntax", ctx)

    def test_grok_toolInput_set_node(self) -> None:
        payload = {
            "sessionId": f"grok-set-{uuid.uuid4()}",
            "hookEventName": "pre_tool_use",
            "toolName": "n8n-mcp__get_node",
            "toolInput": {"nodeType": "nodes-base.set"},
        }
        result = run_script(GET_NODE, payload, tmpdir=self.tmpdir)
        self.assertEqual(result.returncode, 0, result.stderr)
        ctx = context_text(result.stdout)
        self.assertIn("Set node detected", ctx)
        self.assertIn("n8n-expression-syntax", ctx)


class SessionStartTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmpdir = self._tmp.name

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def test_grok_compact_clears_markers_using_sessionId(self) -> None:
        sid = f"grok-compact-{uuid.uuid4()}"
        emit = run_script(
            EMIT,
            {"sessionId": sid},
            extra_args=["node-config", "invoke n8n-node-configuration"],
            tmpdir=self.tmpdir,
        )
        self.assertIn("n8n-node-configuration", context_text(emit.stdout))

        start = run_script(
            SESSION_START,
            {"sessionId": sid, "source": "compact", "hookEventName": "session_start"},
            tmpdir=self.tmpdir,
        )
        self.assertEqual(start.returncode, 0, start.stderr)
        self.assertIn("using-n8n-mcp-skills", context_text(start.stdout))

        again = run_script(
            EMIT,
            {"sessionId": sid},
            extra_args=["node-config", "invoke n8n-node-configuration"],
            tmpdir=self.tmpdir,
        )
        self.assertIn("n8n-node-configuration", context_text(again.stdout))


class PostValidateTests(unittest.TestCase):
    def test_grok_toolInput_workflow_nodes(self) -> None:
        payload = {
            "sessionId": f"grok-val-{uuid.uuid4()}",
            "toolName": "n8n-mcp__validate_workflow",
            "toolInput": {
                "workflow": {
                    "nodes": [
                        {"type": "n8n-nodes-base.set"},
                        {"type": "n8n-nodes-base.merge"},
                    ]
                }
            },
        }
        result = run_script(POST_VALIDATE, payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        ctx = context_text(result.stdout)
        self.assertIn("Set", ctx)
        self.assertIn("Merge", ctx)
        self.assertIn("n8n-expression-syntax", ctx)
        self.assertIn("n8n-node-configuration", ctx)

    def test_claude_tool_input_workflow_nodes_still_work(self) -> None:
        payload = {
            "session_id": f"claude-val-{uuid.uuid4()}",
            "tool_input": {
                "workflow": {
                    "nodes": [{"type": "n8n-nodes-base.code"}]
                }
            },
        }
        result = run_script(POST_VALIDATE, payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("n8n-code-javascript", context_text(result.stdout))


if __name__ == "__main__":
    unittest.main()
