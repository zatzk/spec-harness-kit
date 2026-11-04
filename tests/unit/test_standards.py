#!/usr/bin/env python3
"""Unit tests verifying document standards integrity in rules/standards/."""

from pathlib import Path
import unittest

REPO_ROOT = Path(__file__).resolve().parents[2]


class TestDocumentStandards(unittest.TestCase):

    REQUIRED_STANDARDS = [
        "heilmeier-standard.md",
        "zoom-out-standard.md",
        "implementation-readiness-standard.md",
        "feature-spec-standard.md",
        "re-implementation-standard.md",
        "threat-modeling-standard.md",
    ]

    def test_standards_directory_and_files_exist(self):
        standards_dir = REPO_ROOT / "rules" / "standards"
        self.assertTrue(standards_dir.exists(), f"Missing directory: {standards_dir}")

        for std in self.REQUIRED_STANDARDS:
            std_path = standards_dir / std
            with self.subTest(standard=std):
                self.assertTrue(std_path.exists(), f"Missing required standard file: {std_path}")
                content = std_path.read_text(encoding="utf-8")
                self.assertGreater(len(content.strip()), 100, f"Standard {std} is suspiciously short")
                self.assertTrue(content.startswith("# "), f"Standard {std} does not start with an H1 heading")


if __name__ == "__main__":
    unittest.main()
