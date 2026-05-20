# SPEC-HARNESS-KIT Global Agents 🤖🚀

A unified, centralized harness for specialized AI agents. This repository allows you to maintain a single "source of truth" for your AI engineering workforce and use them globally across multiple AI CLIs without polluting your individual project codebases.

## 🌟 Why SPEC-HARNESS-KIT Global?

- **Zero Pollution:** Your projects stay clean. No more \`.agent/\` or \`.spec-harness-kit-core/\` folders in every repo.
- **Multi-CLI Support:** Write an agent once and use it in Gemini CLI, Claude, Antigravity, Codex, or OpenCode.
- **Portability:** Clone this repo on any machine, run the setup, and your entire workforce is ready to go.
- **Collaborative Brain:** Centralized rules and skills ensure consistency across all your projects.

## 🛠 Supported CLIs

SPEC-HARNESS-KIT Global is designed to work seamlessly with:
- **Gemini CLI** (\`~/.gemini/\`)
- **Claude CLI** (\`~/.claude/\`)
- **Antigravity CLI** (\`~/.antigravity/\`)
- **Codex CLI** (\`~/.codex/\`)
- **OpenCode CLI** (\`~/.config/opencode/\`)

---

## 🚀 Installation

1. **Clone the repository:**
   \`\`\`bash
   git clone https://github.com/YOUR_USERNAME/spec-harness-kit.git ~/Projects/spec-harness-kit
   \`\`\`

2. **Run the installation script:**
   \`\`\`bash
   ~/Projects/spec-harness-kit/scripts/install.sh
   \`\`\`

3. **Reload your CLI:**
   - For Gemini CLI: Run \`/agents reload\` or restart the session.

---

## 👥 Agent Catalog

Call these agents using the \`@\` prefix in your favorite CLI.

| Agent | Description |
| :--- | :--- |
| **@spec-master** | **Master Orchestrator:** Specialized in high-level system orchestration and multi-agent coordination. |
| **@squad-creator** | **Squad Architect:** Analyzes complex tasks to assemble the perfect team of specialized agents. |
| **@architect** | **System Architect:** Expert in software architecture, design patterns, and tech stack selection. |
| **@dev** | **Senior Developer:** Core implementation specialist focused on clean code and logic. |
| **@qa** | **QA Engineer:** Expert in quality assurance, comprehensive test strategy, and bug hunting. |
| **@devops** | **DevOps Engineer:** Expert in CI/CD, repository management, and deployment automation. |
| **@ux-design-expert** | **UX/UI Designer:** Expert in user experience design, atomic design systems, and prototyping. |
| **@pm** | **Product Manager:** Focused on product strategy, feature prioritization, and roadmap planning. |
| **@po** | **Product Owner:** Technical specialist in backlog management and acceptance criteria. |
| **@analyst** | **Business Analyst:** Specialized in requirements gathering and feasibility studies. |
| **@data-engineer** | **Data Engineer:** Specialized in database schema design and migrations. |
| **@sm** | **Scrum Master:** Facilitator for agile workflows and removing technical blockers. |

---

## 📂 Repository Structure

- \`agents/\`: Agnostic Markdown files with standard YAML frontmatter for all agents.
- \`rules/\`: Global rules, constitution, and technical presets (Next.js, React, Rust, Go, etc.).
- \`skills/\`: Specialized SPEC-HARNESS-KIT capabilities (React components, Shadcn UI, Remotion, etc.).
- \`scripts/\`: Automation for wiring the repo to your local system.

## 🧠 Architecture Note

To ensure maximum compatibility across different CLI discovery mechanisms:
- **Agents** are **COPIED** to the global config folders because some CLIs (like Gemini) do not follow symlinks for agent discovery.
- **Rules & Skills** are **SYMLINKED**, allowing for live updates when you modify them in this repository.

---

*Built with ❤️ by SPEC-HARNESS-KIT Master Orchestrator.*
