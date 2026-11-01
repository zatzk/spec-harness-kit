#!/usr/bin/env python3
"""Unit tests verifying bash scripts syntax in scripts/."""

from pathlib import Path
import subprocess
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]


class TestScriptsSyntax(unittest.TestCase):

    def test_all_bash_scripts_pass_syntax_check(self):
        scripts_dir = REPO_ROOT / "scripts"
        self.assertTrue(scripts_dir.exists(), f"Missing scripts dir: {scripts_dir}")

        sh_files = [f for f in scripts_dir.glob("*.sh") if not f.is_symlink()]
        self.assertGreater(len(sh_files), 0, "No .sh script files found")

        for sh_file in sh_files:
            with self.subTest(script=sh_file.name):
                result = subprocess.run(
                    ["bash", "-n", str(sh_file)],
                    capture_output=True,
                    text=True
                )
                self.assertEqual(
                    result.returncode, 0,
                    f"Syntax error in {sh_file.name}:\n{result.stderr}"
                )


if __name__ == "__main__":
    unittest.main()
