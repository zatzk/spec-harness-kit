#!/usr/bin/env python3
"""Unit tests verifying bash scripts syntax in scripts/."""

from pathlib import Path
import subprocess
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]


class TestScriptsSyntax(unittest.TestCase):

    def test_all_bash_scripts_pass_syntax_check(self):
        script_dirs = [REPO_ROOT / "scripts", REPO_ROOT / "hooks"]
        sh_files = []
        for sdir in script_dirs:
            self.assertTrue(sdir.exists(), f"Missing directory: {sdir}")
            sh_files.extend(f for f in sdir.glob("*.sh") if not f.is_symlink())
        self.assertGreater(len(sh_files), 0, "No .sh script files found")

        for sh_file in sh_files:
            with self.subTest(script=f"{sh_file.parent.name}/{sh_file.name}"):
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
