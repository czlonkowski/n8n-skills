#!/usr/bin/env python3
"""Validate the platform-specific hook split without external dependencies."""

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_json(relative_path: str) -> dict:
    with (ROOT / relative_path).open(encoding="utf-8") as handle:
        return json.load(handle)


def normalized_tool_hooks(config: dict) -> dict:
    """Normalize platform-specific plugin-root environment variables."""
    serialized = json.dumps(config)
    serialized = serialized.replace("${CLAUDE_PLUGIN_ROOT}", "${PLUGIN_ROOT}")
    return json.loads(serialized)


def main() -> None:
    claude = load_json("hooks/hooks.json")["hooks"]
    codex = load_json("hooks/hooks-codex.json")["hooks"]
    manifest = load_json(".codex-plugin/plugin.json")

    assert "SessionStart" in claude
    assert "SessionStart" not in codex
    assert set(codex) == {"PreToolUse", "PostToolUse"}

    for event in ("PreToolUse", "PostToolUse"):
        assert normalized_tool_hooks(claude[event]) == codex[event]

    assert manifest["skills"] == "./skills/"
    assert manifest["hooks"] == "./hooks/hooks-codex.json"

    for event_entries in codex.values():
        for entry in event_entries:
            for hook in entry["hooks"]:
                relative_command = hook["command"].replace("${PLUGIN_ROOT}/", "")
                assert (ROOT / relative_command).is_file(), relative_command

    print("Hook configuration split is valid.")


if __name__ == "__main__":
    main()
