# QA Saffira Backend Testing Skill

This skill contains specific guidelines and plans to resolve testing gaps in the `saffira/backend` project.

## Install

This skill is part of the `spec-harness-kit` plugin. Once installed, it is loaded automatically when the QA agent is activated.

## Skill Structure

```text
qa-saffira-backend/
├── SKILL.md           — Core instructions & module-specific blueprints
└── README.md          — This file
```

## How it Works

When this skill is active, the agent:
1. Validates test architecture decisions in `saffira/backend`.
2. Discourages mock abuse, hardcoded timeouts, and direct database seeding.
3. Suggests proper setup and usage for `mongodb-memory-server` and `vi.waitFor`.
