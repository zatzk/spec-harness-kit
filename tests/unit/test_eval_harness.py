#!/usr/bin/env python3
"""Offline unit tests for the Promptfoo evaluation harness components.

Tests prompt_builder.py and dispatch_provider.py without requiring active LLM inference.
"""

import os
from pathlib import Path
import subprocess
import unittest
from unittest.mock import MagicMock, patch

REPO_ROOT = Path(__file__).resolve().parents[2]

# Ensure eval scripts and providers are importable
import sys

sys.path.insert(0, str(REPO_ROOT / "tests" / "eval" / "scripts"))
sys.path.insert(0, str(REPO_ROOT / "tests" / "eval" / "providers"))

import dispatch_provider
import prompt_builder


class TestPromptBuilder(unittest.TestCase):

    def test_strip_frontmatter(self):
        sample = "---\nname: test-agent\ntools: [view]\n---\n# Agent Header\nAgent body content"
        stripped = prompt_builder.strip_frontmatter(sample)
        self.assertEqual(stripped, "# Agent Header\nAgent body content")

    def test_load_agent_instructions_existing(self):
        instructions = prompt_builder.load_agent_instructions("security-reviewer", repo_root=REPO_ROOT)
        self.assertIn("Security Reviewer Subagent", instructions)
        self.assertNotIn("name: security-reviewer", instructions)

    def test_load_agent_instructions_nonexistent(self):
        with self.assertRaises(FileNotFoundError):
            prompt_builder.load_agent_instructions("nonexistent-agent-xyz", repo_root=REPO_ROOT)

    def test_resolve_artifact_content_fixture(self):
        content = prompt_builder.resolve_artifact_content(
            diff_file="diffs/hardcoded-jwt.diff", repo_root=REPO_ROOT
        )
        self.assertIn("super-secret-jwt-token", content)

    def test_build_prompt_envelope(self):
        prompt = prompt_builder.build_prompt(
            agent_name="security-reviewer",
            artifact_content="sample diff content",
            artifact_type="Git Diff",
            repo_root=REPO_ROOT,
        )
        self.assertTrue(prompt.startswith("<system_instructions>"))
        self.assertIn('<target_artifact type="Git Diff">', prompt)
        self.assertIn("sample diff content", prompt)
        self.assertIn("</target_artifact>", prompt)

    def test_get_prompt_context_adapter(self):
        context = {
            "vars": {
                "agent_name": "security-reviewer",
                "diff_file": "diffs/clean-service.diff",
            }
        }
        rendered = prompt_builder.get_prompt(context)
        self.assertIn("Security Reviewer Subagent", rendered)
        self.assertIn("findUserById", rendered)

    def test_promptfooconfig_integrity(self):
        import yaml
        config_path = REPO_ROOT / "tests" / "eval" / "promptfooconfig.yaml"
        self.assertTrue(config_path.exists(), "promptfooconfig.yaml not found")
        data = yaml.safe_load(config_path.read_text(encoding="utf-8"))
        self.assertIn("tests", data)
        self.assertGreater(len(data["tests"]), 0)

        for test_case in data["tests"]:
            vars_dict = test_case.get("vars", {})
            if "diff_file" in vars_dict:
                fixture_path = REPO_ROOT / "tests" / "eval" / "fixtures" / vars_dict["diff_file"]
                self.assertTrue(fixture_path.exists(), f"Fixture referenced in config does not exist: {fixture_path}")
            if "agent_name" in vars_dict:
                agent_path = REPO_ROOT / "agents" / f"{vars_dict['agent_name']}.md"
                self.assertTrue(agent_path.exists(), f"Agent referenced in config does not exist: {agent_path}")


class TestDispatchProvider(unittest.TestCase):

    def test_frontier_guard_blocked_by_default(self):
        with patch.dict(os.environ, {}, clear=True):
            result = dispatch_provider.call_api(
                prompt="Short prompt",
                options={"config": {"tier": "frontier"}},
                context={"vars": {"agent_name": "architect"}},
            )
            self.assertIn("error", result)
            self.assertIn("Scarce Frontier Guard Violation", result["error"])

    def test_frontier_guard_prompt_length_limit(self):
        with patch.dict(os.environ, {"ALLOW_FRONTIER_EVAL": "1"}):
            oversized_prompt = "x" * 3501
            result = dispatch_provider.call_api(
                prompt=oversized_prompt,
                options={"config": {"tier": "frontier"}},
                context={"vars": {"agent_name": "architect"}},
            )
            self.assertIn("error", result)
            self.assertIn("exceeds 3,500 chars", result["error"])

    @patch("subprocess.run")
    def test_happy_path_execution(self, mock_run):
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout="### Status Geral\nSTATUS: PASS\nNenhum problema identificado.",
            stderr="",
        )

        with patch.dict(os.environ, {"SPEC_HARNESS_WORKER": "1"}):
            result = dispatch_provider.call_api(
                prompt="Valid prompt",
                options={"config": {"tier": "standard"}},
                context={"vars": {"agent_name": "security-reviewer"}},
            )

            self.assertIn("output", result)
            self.assertIn("STATUS: PASS", result["output"])

            # Verify that subprocess was called with clean env (SPEC_HARNESS_WORKER unset)
            _, kwargs = mock_run.call_args
            self.assertNotIn("SPEC_HARNESS_WORKER", kwargs["env"])

    @patch("subprocess.run")
    def test_tripwire_exit_code_2(self, mock_run):
        mock_run.return_value = MagicMock(
            returncode=2,
            stdout="",
            stderr="Security Alert",
        )

        result = dispatch_provider.call_api(
            prompt="Valid prompt",
            options={"config": {"tier": "standard"}},
            context={"vars": {"agent_name": "dev"}},
        )
        self.assertIn("error", result)
        self.assertIn("Read-only worker violated plan mode", result["error"])

    @patch("subprocess.run")
    def test_timeout_handling(self, mock_run):
        mock_run.side_effect = subprocess.TimeoutExpired(cmd=["worker-dispatch.sh"], timeout=180)

        result = dispatch_provider.call_api(
            prompt="Valid prompt",
            options={"config": {"tier": "standard"}},
            context={"vars": {"agent_name": "dev"}},
        )
        self.assertIn("error", result)
        self.assertIn("timed out after 180s", result["error"])


if __name__ == "__main__":
    unittest.main()
