# SPEC-HARNESS-KIT Global workforce 🤖🚀

A unified, centralized harness for specialized AI agents. This repository maintains a single "source of truth" for your AI engineering workforce, rules, and skills, allowing you to use them globally across multiple AI CLIs without polluting individual project codebases.

## 🌟 Why SPEC-HARNESS-KIT?

- **Zero Pollution:** Your projects stay clean. No more local `.agent/` or duplicate configuration folders in every repo.
- **Multi-CLI Support:** Built to work with Antigravity, Claude, Codex, OpenCode, and Pi.
- **Portability:** Setup once, run anywhere. Copy or symlink rules and skills locally in seconds.
- **Project-Specific Partitioning:** Clear separation between globally applicable skills and project-specific customizations.

---

## 🛠 Supported CLIs

SPEC-HARNESS-KIT is CLI-agnostic and designed to work with:
- **Antigravity CLI** (`~/.antigravity/` / `~/.gemini/antigravity/`)
- **Claude CLI** (`~/.claude/`)
- **Codex CLI** (`~/.codex/`)
- **OpenCode CLI** (`~/.config/opencode/`)
- **Pi Coding Agent** (`~/.pi/agent/`)

---

## 🚀 Installation

### Option A: Global Installation (Recommended)

Installs the agents, rules, and skills globally to be discovered by your CLIs system-wide:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/spec-harness-kit.git ~/Code/spec-harness-kit
   ```

2. **Run the installation script:**
   ```bash
   ~/Code/spec-harness-kit/scripts/install.sh
   ```

3. **Reload your CLI session** to activate the new agents.

### Option B: Project-Local Installation (For IDE Workspaces / Sandbox environments)

Installs agents, rules, and skills directly inside your target project's `.agents/` folder.

1. **Copy Mode (Self-contained)**
   Copies all assets directly into the project, ensuring the setup is fully portable:
   ```bash
   cd ~/Work/my-project
   ~/Code/spec-harness-kit/scripts/install-project.sh
   ```

2. **Symlink Mode (Active Development)**
   Creates symbolic links back to the source repository so any changes you make in your local clone are reflected immediately:
   ```bash
   cd ~/Work/my-project
   ~/Code/spec-harness-kit/scripts/install-project.sh -s
   ```

---

## 👥 Agent Catalog

Call these agents using the `@` prefix in your favorite CLI.

| Agent | Description | Primary Deliverables |
| :--- | :--- | :--- |
| **@spec-master** | **Master Orchestrator:** High-level coordinator, decomposes complex requests into phases. | Implementation Plans, task specs. |
| **@squad-creator** | **Squad Architect:** Analyzes tasks to assemble specialized agent teams. | Squad Manifests, team protocols. |
| **@architect** | **System Architect:** Designs tech stacks, interfaces, patterns, and boundaries. | Architecture Design Docs (Mermaid). |
| **@dev** | **Senior Developer:** Implementation specialist, clean code, unit/integration tests. | Source files, test suites. |
| **@qa** | **QA Engineer:** Exclusive authority for quality verdicts (PASS/FAIL), test strategies. | QA Review Reports, Bug logs. |
| **@devops** | **DevOps Engineer:** Exclusive authority for git pushes, CI/CD, and deployments. | CI/CD pipelines, container configs. |
| **@ux-design-expert** | **UX/UI Designer:** Enforces atomic design systems, visual consistency, and micro-animations. | Design System Specs (`DESIGN.md`). |
| **@pm** | **Product Manager:** Drives product strategy, feature roadmap, and user value definition. | Product Requirement Docs (PRDs). |
| **@po** | **Product Owner:** Splits requirements into stories, backlog, and acceptance criteria. | Refined user stories, backlog grids. |
| **@analyst** | **Business Analyst:** Requirements gathering, feasibility studies, and functional specs. | Functional specs (`spec.md`). |
| **@data-engineer** | **Data Engineer:** Designs database schemas, migrations, query plans, and index maps. | Database migration files, models. |
| **@sm** | **Scrum Master:** Facilitator for agile workflows, sprints, and removing blockers. | Sprint status reports, blocker logs. |

---

## 📂 Repository Structure

- `agents/`: Agnostic Markdown files with standard YAML frontmatter defining each agent's behavior (in English).
- `rules/`: Global rules, constitutions, tech-presets, and templates.
- `skills/`: Global, reusable capabilities:
  - `design-md/`: Synthesizes semantic design systems into `DESIGN.md`.
  - `enhance-prompt/`: Transforms vague UI ideas into Stitch-optimized prompts.
  - `gitlab-mr-review/`: Automated code reviews for GitLab Merge Requests.
  - `react-components/`: Converts visual HTML designs into modular React/Vite components.
  - `remotion/`: Programmatic walkthrough video generation.
  - `shadcn-ui/`: Expert component discovery, addition, and customization.
  - `stitch-loop/`: Autonomous iteration loop for front-end building.
- `skills/projects/`: Project-specific or custom capabilities:
  - `qa-saffira-backend/`: Mocks, async testing rules, and patterns for saffira/backend.
  - `qa-saffira-admin-backend/`: Vitest + Testcontainers configs for saffira-admin/backend.
- `scripts/`: Automation scripts for global and project-local configuration.
