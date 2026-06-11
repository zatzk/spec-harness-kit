# QA Saffira-Admin Backend Testing Skill

This skill contains specific guidelines and plans to resolve testing gaps in the `saffira-admin/backend` project.

## Install

This skill is part of the `spec-harness-kit` plugin. Once installed, it is loaded automatically when the QA agent is activated.

## Skill Structure

```text
qa-saffira-admin-backend/
├── SKILL.md           — Core instructions & module-specific blueprints
└── README.md          — This file
```

## How it Works

When this skill is active, the agent:
1. Validates test architecture decisions in `saffira-admin/backend`.
2. Verifies network border security coverage, tenant boundaries, and asynchronous notifications/email flow test cases.
3. Suggests proper setup and usage for `@testcontainers/mongodb` and `@testcontainers/minio`.
