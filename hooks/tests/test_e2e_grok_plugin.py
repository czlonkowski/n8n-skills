#!/usr/bin/env python3
"""End-to-end: an installed Grok plugin must expose the n8n-mcp-skills catalog."""

from __future__ import annotations

import json
import shutil
import subprocess
import unittest

REQUIRED_SKILLS = {
    "using-n8n-mcp-skills",
    "n8n-mcp-tools-expert",
    "n8n-expression-syntax",
    "n8n-workflow-patterns",
    "n8n-validation-expert",
    "n8n-node-configuration",
    "n8n-code-javascript",
    "n8n-code-python",
    "n8n-code-tool",
    "n8n-error-handling",
    "n8n-binary-and-data",
    "n8n-subworkflows",
    "n8n-agents",
    "n8n-multi-instance",
    "n8n-self-hosting",
}


def inspect() -> dict:
    grok = shutil.which("grok")
    if grok is None:
        raise unittest.SkipTest("grok CLI is not on PATH")
    result = subprocess.run(
        [grok, "inspect", "--json"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise AssertionError(f"grok inspect failed: {result.stderr or result.stdout}")
    return json.loads(result.stdout)


class GrokPluginE2E(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.report = inspect()

    def test_plugin_is_enabled(self) -> None:
        plugins = {p.get("name"): p for p in self.report.get("plugins") or []}
        self.assertIn("n8n-mcp-skills", plugins)
        self.assertTrue(plugins["n8n-mcp-skills"].get("enabled"))

    def test_fifteen_skills_are_in_the_catalog(self) -> None:
        names = {s.get("name") for s in self.report.get("skills") or []}
        missing = REQUIRED_SKILLS - names
        self.assertFalse(missing, f"skills discovered by the plugin but not in catalog: {sorted(missing)}")

    def test_skills_are_attributed_to_the_plugin(self) -> None:
        attributed = {
            s.get("name")
            for s in self.report.get("skills") or []
            if s.get("plugin") == "n8n-mcp-skills"
            or (s.get("source") or {}).get("plugin_name") == "n8n-mcp-skills"
        }
        missing = REQUIRED_SKILLS - attributed
        self.assertFalse(missing, f"skills present but not sourced from n8n-mcp-skills: {sorted(missing)}")


if __name__ == "__main__":
    unittest.main()
