#!/usr/bin/env python3
"""Offline unit tests for the Promptfoo evaluation harness components.

Tests prompt_builder.py and dispatch_provider.py without requiring active LLM inference.
"""

import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
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

    def test_mock_mode_handles_rls_shortcut_and_bug_repro(self):
        with patch.dict(os.environ, {"MOCK_WORKER_DISPATCH": "1"}):
            res_rls = dispatch_provider.call_api(
                prompt="ALTER TABLE user_records DISABLE ROW LEVEL SECURITY;",
                options={"config": {"tier": "standard"}},
                context={"vars": {"agent_name": "security-reviewer"}},
            )
            self.assertIn("STATUS: FAIL", res_rls["output"])
            self.assertIn("SERVICE_ROLE_KEY", res_rls["output"])

            res_bug = dispatch_provider.call_api(
                prompt="Submitting coupon SAVE10 returns NaN",
                options={"config": {"tier": "standard"}},
                context={"vars": {"agent_name": "dev"}},
            )
            self.assertIn("RED", res_bug["output"])

    @patch("subprocess.run")
    def test_sandbox_exit_code_78(self, mock_run):
        mock_run.return_value = MagicMock(
            returncode=78,
            stdout="",
            stderr="🛑 Sandbox Error: ai-jail preflight reported blockers",
        )

        result = dispatch_provider.call_api(
            prompt="Valid prompt",
            options={"config": {"tier": "standard", "sandbox": "require"}},
            context={"vars": {"agent_name": "dev"}},
        )
        self.assertIn("error", result)
        self.assertIn("Sandbox Configuration Error (exit 78)", result["error"])


class TestWorkerDispatchSandboxIntegration(unittest.TestCase):
    """End-to-end execution tests for scripts/worker-dispatch.sh ai-jail integration."""

    DISPATCH_SCRIPT = REPO_ROOT / "scripts" / "worker-dispatch.sh"

    def _write_executable(self, path: Path, content: str) -> None:
        path.write_text(content, encoding="utf-8")
        path.chmod(path.stat().st_mode | stat.S_IEXEC)

    def test_auto_sandbox_enforces_ai_jail_when_preflight_passes(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            bin_dir = tmp_path / "bin"
            bin_dir.mkdir()
            worktree_dir = tmp_path / "worktree"
            worktree_dir.mkdir()
            # Simulate a linked git worktree (.git as a file)
            (worktree_dir / ".git").write_text("gitdir: /tmp/fake-main/.git/worktrees/wt1\n", encoding="utf-8")
            telemetry_file = tmp_path / "telemetry.jsonl"
            egress_dir = tmp_path / "egress"

            self._write_executable(
                bin_dir / "ai-jail",
                "#!/usr/bin/env bash\n"
                "for arg in \"$@\"; do\n"
                "  if [[ \"$arg\" == \"status\" ]]; then\n"
                "    echo '{\"version\":\"3.0.1\",\"schema_version\":1,\"blockers\":[]}'\n"
                "    exit 0\n"
                "  fi\n"
                "done\n"
                "echo \"JAILED_ARGS:$*\"\n"
                "while [[ $# -gt 0 ]]; do\n"
                "  if [[ \"$1\" == \"--\" ]]; then shift; break; fi\n"
                "  shift\n"
                "done\n"
                "exec \"$@\"\n",
            )
            self._write_executable(
                bin_dir / "claude",
                "#!/usr/bin/env bash\n"
                "echo \"CLAUDE_OK:$*\"\n",
            )

            env = os.environ.copy()
            env.pop("SPEC_HARNESS_WORKER", None)
            env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"
            env["SPEC_ORCHESTRATOR_PROVIDER"] = "claude"
            env["SPEC_TELEMETRY_LOG"] = str(telemetry_file)
            env["SPEC_EGRESS_LOG_DIR"] = str(egress_dir)
            env["SPEC_SANDBOX_EXTRA_HOSTS"] = "gitlab.internal.local"
            # Leave SPEC_SANDBOX unset to verify default is 'auto'
            env.pop("SPEC_SANDBOX", None)

            res = subprocess.run(
                [str(self.DISPATCH_SCRIPT), "standard", "plan", "dev", "Audit auth module", str(worktree_dir)],
                capture_output=True,
                text=True,
                env=env,
            )
            self.assertEqual(res.returncode, 0, f"Unexpected failure: {res.stderr}")
            self.assertIn("JAILED_ARGS:--harness claude --no-save-config --mask .env --mask .env.* --worktree --no-toolchains --allow-host gitlab.internal.local", res.stdout)
            self.assertIn("CLAUDE_OK:", res.stdout)

            telemetry = json.loads(telemetry_file.read_text(encoding="utf-8").strip())
            self.assertEqual(telemetry["sandbox_mode"], "ai-jail")
            self.assertEqual(telemetry["sandbox_status"], "enforced")
            self.assertTrue(telemetry["egress_log"].startswith(str(egress_dir)))

    def test_auto_sandbox_falls_back_when_preflight_reports_blockers(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            bin_dir = tmp_path / "bin"
            bin_dir.mkdir()
            telemetry_file = tmp_path / "telemetry.jsonl"

            self._write_executable(
                bin_dir / "ai-jail",
                "#!/usr/bin/env bash\n"
                "echo '{\"version\":\"3.0.1\",\"schema_version\":1,\"blockers\":[\"onboarding_required\"]}'\n"
                "exit 3\n",
            )
            self._write_executable(
                bin_dir / "claude",
                "#!/usr/bin/env bash\n"
                "echo \"UNJAILED_CLAUDE_OK\"\n",
            )

            env = os.environ.copy()
            env.pop("SPEC_HARNESS_WORKER", None)
            env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"
            env["SPEC_ORCHESTRATOR_PROVIDER"] = "claude"
            env["SPEC_TELEMETRY_LOG"] = str(telemetry_file)
            env["SPEC_SANDBOX"] = "auto"

            res = subprocess.run(
                [str(self.DISPATCH_SCRIPT), "standard", "write", "dev", "Implement fix", str(tmp_path)],
                capture_output=True,
                text=True,
                env=env,
            )
            self.assertEqual(res.returncode, 0)
            self.assertIn("UNJAILED_CLAUDE_OK", res.stdout)
            self.assertIn("falling back to unjailed run", res.stderr)

            telemetry = json.loads(telemetry_file.read_text(encoding="utf-8").strip())
            self.assertEqual(telemetry["sandbox_mode"], "off")
            self.assertEqual(telemetry["sandbox_status"], "fallback-unconfigured")

    def test_require_sandbox_fails_closed_with_exit_78_on_preflight_blocker(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            bin_dir = tmp_path / "bin"
            bin_dir.mkdir()

            self._write_executable(
                bin_dir / "ai-jail",
                "#!/usr/bin/env bash\n"
                "echo '{\"version\":\"3.0.1\",\"schema_version\":1,\"blockers\":[\"onboarding_required\"]}'\n"
                "exit 3\n",
            )
            self._write_executable(
                bin_dir / "claude",
                "#!/usr/bin/env bash\n"
                "echo \"SHOULD_NOT_RUN\"\n",
            )

            env = os.environ.copy()
            env.pop("SPEC_HARNESS_WORKER", None)
            env["PATH"] = f"{bin_dir}:{env.get('PATH', '')}"
            env["SPEC_ORCHESTRATOR_PROVIDER"] = "claude"
            env["SPEC_SANDBOX"] = "require"

            res = subprocess.run(
                [str(self.DISPATCH_SCRIPT), "standard", "write", "dev", "Implement fix", str(tmp_path)],
                capture_output=True,
                text=True,
                env=env,
            )
            self.assertEqual(res.returncode, 78)
            self.assertNotIn("SHOULD_NOT_RUN", res.stdout)
            self.assertIn("ai-jail configure claude", res.stderr)


if __name__ == "__main__":
    unittest.main()
