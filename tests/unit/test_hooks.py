#!/usr/bin/env python3
"""Offline unit tests for deterministic harness hooks in hooks/."""

import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOKS_DIR = REPO_ROOT / "hooks"


def run_hook(script_name: str, payload: dict | None = None, cwd: str | None = None, env_extra: dict | None = None):
    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    return subprocess.run(
        ["bash", str(HOOKS_DIR / script_name)],
        input=json.dumps(payload) if payload is not None else "",
        capture_output=True,
        text=True,
        cwd=cwd or str(REPO_ROOT),
        env=env,
    )


class TestHarnessHooks(unittest.TestCase):

    def test_pre_tool_blocks_env_file_access(self):
        res = run_hook("pre-tool-guard.sh", {"tool_input": {"file_path": "/app/.env.production"}})
        self.assertEqual(res.returncode, 2)
        self.assertIn("BLOCKED", res.stderr)

    def test_pre_tool_allows_env_example(self):
        res = run_hook("pre-tool-guard.sh", {"tool_input": {"file_path": "/app/.env.example"}})
        self.assertEqual(res.returncode, 0)

    def test_pre_tool_blocks_git_push_unless_devops_or_docs(self):
        res_blocked = run_hook("pre-tool-guard.sh", {"tool_input": {"command": "git push origin main"}})
        self.assertEqual(res_blocked.returncode, 2)

        res_docs = run_hook("pre-tool-guard.sh", {"tool_input": {"command": "git -C code-documentation push origin main"}})
        self.assertEqual(res_docs.returncode, 0)

        res_devops = run_hook(
            "pre-tool-guard.sh",
            {"tool_input": {"command": "git push origin main"}},
            env_extra={"SPEC_AGENT_ROLE": "devops"},
        )
        self.assertEqual(res_devops.returncode, 0)

    def test_post_edit_flags_secret_fallback_any_and_debug(self):
        with tempfile.TemporaryDirectory() as tmp:
            bad_ts = Path(tmp) / "bad.ts"
            bad_ts.write_text(
                "const k = process.env.JWT_SECRET || 'dev-secret';\n"
                "const x: any = 1;\n"
                "console.log('[DEBUG-123] hit');\n",
                encoding="utf-8",
            )
            res = run_hook("post-edit-guard.sh", {"tool_input": {"file_path": str(bad_ts)}}, cwd=tmp)
            self.assertEqual(res.returncode, 2)
            self.assertIn("Hardcoded env fallback", res.stderr)
            self.assertIn("forbidden 'any'", res.stderr)
            self.assertIn("leftover debug tag", res.stderr)

            clean_ts = Path(tmp) / "clean.ts"
            clean_ts.write_text("export const add = (a: number, b: number): number => a + b;\n", encoding="utf-8")
            res_clean = run_hook("post-edit-guard.sh", {"tool_input": {"file_path": str(clean_ts)}}, cwd=tmp)
            self.assertEqual(res_clean.returncode, 0)

    def test_stop_verify_gate_blocks_failing_check_and_clears_on_pass(self):
        with tempfile.TemporaryDirectory() as tmp:
            code_file = Path(tmp) / "app.ts"
            code_file.write_text("export const ok = true;\n", encoding="utf-8")
            # Mark dirty via post-edit-guard
            res_edit = run_hook("post-edit-guard.sh", {"tool_input": {"file_path": str(code_file)}}, cwd=tmp)
            self.assertEqual(res_edit.returncode, 0)

            res_fail = run_hook("stop-verify-gate.sh", cwd=tmp, env_extra={"SPEC_VERIFY_CMD": "exit 1"})
            self.assertEqual(res_fail.returncode, 2)
            self.assertIn("BLOCKED by stop-verify-gate", res_fail.stderr)

            res_pass = run_hook("stop-verify-gate.sh", cwd=tmp, env_extra={"SPEC_VERIFY_CMD": "true"})
            self.assertEqual(res_pass.returncode, 0)

            # Second stop call should pass immediately because dirty marker was cleared
            ws_hash = hashlib.sha256(tmp.encode("utf-8")).hexdigest()[:12]
            marker = Path(os.environ.get("TMPDIR", "/tmp")) / f"spec-harness-dirty-{ws_hash}"
            self.assertFalse(marker.exists())


if __name__ == "__main__":
    unittest.main()
