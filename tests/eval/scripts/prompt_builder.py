#!/usr/bin/env python3
"""Prompt builder for spec-harness-kit evaluation with Promptfoo.

Extracts system prompts from agents/<agent>.md (stripping YAML frontmatter)
and combines them with target fixtures (diffs, specs, code) into a self-contained
envelope without polluting original agent markdown files with template variables.
"""

import os
from pathlib import Path
import re
import sys

REPO_ROOT = Path(__file__).resolve().parents[3]


def strip_frontmatter(content: str) -> str:
    """Remove leading YAML frontmatter delimited by ---."""
    cleaned = re.sub(r"^---\n.*?\n---\n", "", content, flags=re.DOTALL)
    return cleaned.strip()


def load_agent_instructions(agent_name: str, repo_root: Path = REPO_ROOT) -> str:
    """Load system instructions for a given agent by name."""
    agent_path = repo_root / "agents" / f"{agent_name}.md"
    if not agent_path.exists():
        raise FileNotFoundError(f"Agent spec not found: {agent_path}")
    raw_content = agent_path.read_text(encoding="utf-8")
    return strip_frontmatter(raw_content)


def resolve_artifact_content(
    diff: str = "", diff_file: str = "", repo_root: Path = REPO_ROOT
) -> str:
    """Resolve artifact content from inline string or relative file path."""
    if diff_file:
        file_path = repo_root / "tests" / "eval" / "fixtures" / diff_file
        if not file_path.exists():
            # Try direct relative path
            file_path = repo_root / diff_file
        if not file_path.exists():
            raise FileNotFoundError(f"Fixture file not found: {diff_file}")
        return file_path.read_text(encoding="utf-8").strip()
    return diff.strip()


def build_prompt(
    agent_name: str,
    artifact_content: str,
    artifact_type: str = "Git Diff",
    repo_root: Path = REPO_ROOT,
) -> str:
    """Combine agent instructions and target artifact into an evaluation envelope."""
    instructions = load_agent_instructions(agent_name, repo_root=repo_root)
    return (
        f"<system_instructions>\n"
        f"{instructions}\n"
        f"</system_instructions>\n\n"
        f'<target_artifact type="{artifact_type}">\n'
        f"{artifact_content}\n"
        f"</target_artifact>\n\n"
        f"Por favor, realize a auditoria estrita do artefato acima conforme suas "
        f"diretrizes de especialista e retorne sua análise no formato especificado pelo seu Output Schema."
    )


def get_prompt(context: dict) -> str:
    """Promptfoo python prompt provider entrypoint."""
    vars_dict = context.get("vars", {}) if isinstance(context, dict) else {}
    agent_name = vars_dict.get("agent_name", "security-reviewer")
    diff = vars_dict.get("diff", "")
    diff_file = vars_dict.get("diff_file", "")
    artifact_type = vars_dict.get("artifact_type", "Git Diff")

    content = resolve_artifact_content(diff=diff, diff_file=diff_file)
    return build_prompt(agent_name, content, artifact_type=artifact_type)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(
            "Uso: prompt_builder.py <agent-name> [diff-file-or-string]",
            file=sys.stderr,
        )
        sys.exit(1)

    cli_agent = sys.argv[1]
    cli_artifact = ""
    if len(sys.argv) >= 3:
        target = sys.argv[2]
        if os.path.exists(target):
            cli_artifact = Path(target).read_text(encoding="utf-8")
        else:
            cli_artifact = target

    print(build_prompt(cli_agent, cli_artifact))
