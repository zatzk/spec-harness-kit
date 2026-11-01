#!/usr/bin/env python3
"""Unit tests verifying YAML frontmatter integrity across all agents and skills."""

import os
from pathlib import Path
import unittest
import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]


class TestFrontmatter(unittest.TestCase):

    def test_all_agents_have_valid_frontmatter(self):
        agents_dir = REPO_ROOT / "agents"
        self.assertTrue(agents_dir.exists(), f"Directory missing: {agents_dir}")

        agent_files = list(agents_dir.glob("*.md"))
        self.assertGreater(len(agent_files), 0, "No agent files found")

        for agent_file in agent_files:
            with self.subTest(agent=agent_file.name):
                content = agent_file.read_text(encoding="utf-8")
                self.assertTrue(
                    content.startswith("---"),
                    f"{agent_file.name} does not start with YAML frontmatter delimiter '---'"
                )
                parts = content.split("---", 2)
                self.assertGreaterEqual(
                    len(parts), 3,
                    f"{agent_file.name} missing closing YAML frontmatter delimiter '---'"
                )
                raw_yaml = parts[1]
                data = yaml.safe_load(raw_yaml)
                self.assertIsInstance(data, dict, f"{agent_file.name} frontmatter is not a mapping")
                self.assertIn("name", data, f"{agent_file.name} missing 'name' in frontmatter")
                self.assertIn("description", data, f"{agent_file.name} missing 'description' in frontmatter")
                self.assertTrue(bool(data["name"].strip()), f"{agent_file.name} 'name' is empty")
                self.assertTrue(bool(data["description"].strip()), f"{agent_file.name} 'description' is empty")

    def test_all_skills_have_valid_frontmatter(self):
        skills_dir = REPO_ROOT / "skills"
        self.assertTrue(skills_dir.exists(), f"Directory missing: {skills_dir}")

        skill_files = list(skills_dir.glob("*/SKILL.md"))
        self.assertGreater(len(skill_files), 0, "No SKILL.md files found")

        for skill_file in skill_files:
            skill_name = skill_file.parent.name
            with self.subTest(skill=skill_name):
                content = skill_file.read_text(encoding="utf-8")
                self.assertTrue(
                    content.startswith("---"),
                    f"{skill_file} does not start with YAML frontmatter delimiter '---'"
                )
                parts = content.split("---", 2)
                self.assertGreaterEqual(
                    len(parts), 3,
                    f"{skill_file} missing closing YAML frontmatter delimiter '---'"
                )
                raw_yaml = parts[1]
                data = yaml.safe_load(raw_yaml)
                self.assertIsInstance(data, dict, f"{skill_file} frontmatter is not a mapping")
                self.assertIn("name", data, f"{skill_file} missing 'name' in frontmatter")
                self.assertIn("description", data, f"{skill_file} missing 'description' in frontmatter")


if __name__ == "__main__":
    unittest.main()
