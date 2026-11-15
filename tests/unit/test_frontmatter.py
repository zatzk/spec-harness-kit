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

    def test_rules_md_context_budget(self):
        rules_path = REPO_ROOT / "rules" / "rules.md"
        self.assertTrue(rules_path.exists(), "rules/rules.md missing")
        content = rules_path.read_text(encoding="utf-8")
        self.assertLessEqual(
            len(content), 2200,
            f"rules/rules.md exceeds 2200 char always-loaded budget ({len(content)} chars)"
        )
        for stale in ("spec-harness-kit-core/", "require('fs-extra')", "docs/stories/"):
            self.assertNotIn(stale, content, f"Stale boilerplate found in rules/rules.md: {stale}")

    def test_skill_descriptions_context_budget(self):
        skills_dir = REPO_ROOT / "skills"
        total_chars = 0
        for skill_file in skills_dir.glob("*/SKILL.md"):
            parts = skill_file.read_text(encoding="utf-8").split("---", 2)
            data = yaml.safe_load(parts[1]) or {}
            desc = str(data.get("description", ""))
            total_chars += len(desc)
            self.assertLessEqual(
                len(desc), 450,
                f"Skill {skill_file.parent.name} description exceeds 450 chars ({len(desc)})"
            )
        self.assertLessEqual(
            total_chars, 12000,
            f"Combined skill description budget exceeded: {total_chars} > 12000 chars"
        )

    def test_agent_rule_mirror_parity(self):
        agents_dir = REPO_ROOT / "agents"
        rules_dir = REPO_ROOT / "rules"
        for agent_file in agents_dir.glob("*.md"):
            mirrored_rule = rules_dir / agent_file.name
            if mirrored_rule.exists():
                with self.subTest(mirror=agent_file.name):
                    self.assertEqual(
                        agent_file.read_text(encoding="utf-8"),
                        mirrored_rule.read_text(encoding="utf-8"),
                        f"Drift detected between agents/{agent_file.name} and rules/{agent_file.name}"
                    )


if __name__ == "__main__":
    unittest.main()
