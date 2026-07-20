#!/usr/bin/env python3
"""Validate the platform-specific hook split without external dependencies."""

import json
import os
from pathlib import Path
import subprocess
import uuid


ROOT = Path(__file__).resolve().parents[1]
CODEX_RUNNER_PREFIX = '"${PLUGIN_ROOT}/hooks/run-hook.cmd" '


def load_json(relative_path: str) -> dict:
    with (ROOT / relative_path).open(encoding="utf-8") as handle:
        return json.load(handle)


def normalized_tool_hooks(config: dict) -> dict:
    """Normalize platform-specific plugin-root environment variables."""
    normalized = json.loads(json.dumps(config))
    for entry in normalized:
        for hook in entry["hooks"]:
            command = hook["command"]
            if command.startswith(CODEX_RUNNER_PREFIX):
                command = "${PLUGIN_ROOT}/hooks/" + command[len(CODEX_RUNNER_PREFIX) :]
            hook["command"] = command.replace(
                "${CLAUDE_PLUGIN_ROOT}",
                "${PLUGIN_ROOT}",
            )
    return normalized


def verify_codex_runner() -> None:
    runner = ROOT / "hooks" / "run-hook.cmd"
    assert runner.is_file(), "Codex hook runner is missing"

    session_id = f"hook-runner-test-{uuid.uuid4()}"
    if os.name == "nt":
        command = ["cmd.exe", "/d", "/c", str(runner)]
    else:
        command = ["bash", str(runner)]

    result = subprocess.run(
        command
        + ["pre-tool-use/_emit.sh", "runner-test", "runner works"],
        input=json.dumps({"session_id": session_id}),
        text=True,
        capture_output=True,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    payload = json.loads(result.stdout)
    assert payload["hookSpecificOutput"]["additionalContext"] == "runner works"


def main() -> None:
    claude = load_json("hooks/hooks.json")["hooks"]
    codex = load_json("hooks/hooks-codex.json")["hooks"]
    manifest = load_json(".codex-plugin/plugin.json")

    assert "SessionStart" in claude
    assert "SessionStart" not in codex
    assert set(codex) == {"PreToolUse", "PostToolUse"}

    for event in ("PreToolUse", "PostToolUse"):
        assert normalized_tool_hooks(claude[event]) == normalized_tool_hooks(codex[event])

    assert manifest["skills"] == "./skills/"
    assert manifest["hooks"] == "./hooks/hooks-codex.json"

    for event_entries in codex.values():
        for entry in event_entries:
            for hook in entry["hooks"]:
                assert hook["command"].startswith(CODEX_RUNNER_PREFIX)
                relative_command = hook["command"][len(CODEX_RUNNER_PREFIX) :]
                assert (ROOT / "hooks" / relative_command).is_file(), relative_command

    verify_codex_runner()

    print("Hook configuration split is valid.")


if __name__ == "__main__":
    main()
