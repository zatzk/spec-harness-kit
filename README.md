# SPEC-HARNESS-KIT Global Workforce 🤖🚀

A unified, centralized harness for specialized AI agents, domain reviewers, rules, and skills. This repository maintains a single "source of truth" for your AI engineering workforce, allowing you to use them globally across multiple AI CLIs and the Antigravity IDE without polluting individual project codebases.

---

## 🌟 Key Capabilities & Highlights

- **Zero Pollution:** Your repositories stay clean. No duplicated `.agent/` or divergent config files scattered across projects.
- **Multi-CLI Compatibility:** Seamlessly integrates with Antigravity (`~/.gemini/antigravity/`), Claude (`~/.claude/`), Codex, OpenCode, and Pi.
- **🔌 Workspace Plugs Engine (`plugs/`):** Dynamically mounts workspace-scoped rules, specialist reviewers, skills, and MCPs (e.g., `aton`, `saffira`, `saffira-admin`, or `personal`) based on folder context or prompt keywords.
- **📐 5-Phase Spec-Driven Architecture Pipeline:** Multi-agent collaboration refining product ideas from rough stories into verified PRDs with ASRs, technical RFCs, and test-first implementation plans.
- **🛡️ Forensic 11-Step Code Review (Addy Osmani Standard):** Deterministic quality assurance matrix with prior comments deduplication (`gh pr view --comments`), 5-axis quality evaluation, concrete structural remedies, Big-O algorithm analysis, PRD/RFC traceability matrix, and prioritized ROI action tables.
- **🛑 Hardened Developer Invariants (`@dev`):** Zero-tolerance for hardcoded fallback secrets, mandatory repository convention inspection (separate Angular files vs inline templates), and strict framework version discipline.
- **⚡ Cost-Optimized Tiered Model Economics:** Fast scraping & data harvesting workers in **Gemini 3.8 Flash** with deep reasoning and architectural synthesis in **Claude Sonnet 4.6 (Thinking)**.

---

## 🛠 Supported CLIs & Environments

SPEC-HARNESS-KIT is CLI-agnostic and designed to work with:
- **Antigravity IDE & CLI** (`~/.antigravity/` / `~/.gemini/antigravity/` / `.gemini/config/plugins/`)
- **Claude CLI** (`~/.claude/`)
- **Codex CLI** (`~/.codex/`)
- **OpenCode CLI** (`~/.config/opencode/`)
- **Pi Coding Agent** (`~/.pi/agent/`)

---

## 🚀 Installation & Synchronization

### Option A: Global Installation (System-Wide)

Installs agents, rules, and skills globally to be discovered across all CLIs:

```bash
git clone https://github.com/zatzk/spec-harness-kit.git ~/Code/spec-harness-kit
~/Code/spec-harness-kit/scripts/install.sh
```

### Option B: Workspace / Project Installation

Configures agents, rules, and workflows directly inside a target workspace or project (e.g., `~/Work/Aton` or `~/MyProjects`):

```bash
# Copy Mode (Self-contained, portable)
~/Code/spec-harness-kit/scripts/install-project.sh ~/Work/Aton

# Symlink Mode (Active Development)
~/Code/spec-harness-kit/scripts/install-project.sh -s ~/MyProjects
```

---

## 👥 Agent Catalog

### 1. Core Engineering & Product Workforce

Call these agents using the `@` prefix in your favorite CLI or Antigravity chat.

| Agent | Description | Primary Deliverables |
| :--- | :--- | :--- |
| **@spec-master** | **Master Orchestrator:** Coordinates multi-agent workflows across PRD, RFC, Dev, and QA pipelines. | Implementation Plans, Orchestration Blueprints. |
| **@architect** | **System Architect:** Leads technical RFC generation, distributed topologies, failure modes, and CAP trade-offs. | Technical RFCs, Mermaid Topologies, ROI Decision Tables. |
| **@dev** | **Senior Developer:** Implementation specialist enforcing Zero-Hardcoded-Fallbacks, repository file conventions, and framework version fidelity. | Source files, unit/integration test suites. |
| **@qa** | **QA Lead Orchestrator:** Coordinates 11-step Review-over-Review pipeline, deduplicates prior comments, checks PRD/RFC traceability. | Unified Code Review Reports, QA Score. |
| **@qa-scout** | **QA Scout / Scraper:** Ultra-fast worker for harvesting diffs, PR comments, and domain AST parsing with minimal tokens. | Inspection Manifest (YAML). |
| **@pm** | **Product Manager:** Drives product strategy, feature roadmap, and PRDs with ASR identification. | Product Requirement Docs (PRDs). |
| **@po** | **Product Owner:** Splits requirements into atomic stories, backlog, and acceptance criteria. | Refined user stories, acceptance criteria. |
| **@analyst** | **Business Analyst:** Requirements elicitation, feasibility studies, and functional specifications. | Functional specs (`spec.md`). |
| **@squad-creator** | **Squad Architect:** Assembles specialized agent squads based on task complexity. | Squad Manifests, Team Protocols. |
| **@data-engineer** | **Data Engineer:** Designs database schemas, migrations, query plans, and dba-harness compliance. | Reversible migrations, models, query optimizations. |
| **@devops** | **DevOps Engineer:** Exclusive authority for git pushes, CI/CD pipelines, and deployment automation. | CI/CD pipelines, container configs, deploy scripts. |
| **@ux** | **UX/UI Designer:** Enforces atomic design systems, visual consistency, and micro-animations. | Design System Specs (`DESIGN.md`). |
| **@writer** | **Technical Writer:** Specialized in documentation, blog posts, changelogs, and content lifecycle. | Technical documentation, blog drafts, changelogs. |
| **@sm** | **Scrum Master:** Facilitator for agile workflows, sprints, and removing blockers. | Sprint status reports, blocker logs. |
| **@researcher** | **Researcher:** Documentation harvesting, API fact-finding, and deep-dive exploration. | Structured Research Notes. |
| **@wayfinder** | **Strategic Planner:** Strategic project mapping, fog-of-war deconstruction, and ticket planning. | Local Markdown Map files (`map.md`), decision tickets. |

### 2. Specialized Reviewers (Workspace Plugs)

Domain-specific subagents dispatched during the Review-over-Review and Review-over-RFC pipelines:

| Specialist Agent | Domain & Focus | Key Standards / Harnesses |
| :--- | :--- | :--- |
| **@security-reviewer** | AppSec, Token Fallbacks & Secrets | OWASP Top 10, Secrets Exposure, `security-harness.md` |
| **@algorithm-complexity-reviewer** | Big-O, Performance & Resource Limits | N+1 Query Detection, Redis Loops (MGET/Pipelines), OOM, Cardinality |
| **@dba-reviewer** | Database Performance & Schemas | Reversible Migrations, Indexes, Constraints, `dba-harness.md` |
| **@architecture-reviewer** | High-Level Design (HLD) & Systems | CAP Theorem, Saga, Outbox, CQRS, Mermaid Topology |
| **@lld-reviewer** | Low-Level Design (LLD) & SOLID | SOLID Principles, 9 Object Calisthenics Rules, GoF Patterns |
| **@angular-reviewer** | Angular Frontend Architecture | Signals, Control Flow (`@if`/`@for`), OnPush, PrimeNG wrappers, `type` vs `interface` |
| **@backend-reviewer** | REST APIs & Node.js/TS Backend | Layer Separation, Clean DTOs, Error Handling Contracts |
| **@qa-reviewer** | Test Architecture & Assertiveness | Value-Oriented Testing, Tautological Mock Audit, QA Score |
| **@saffira-backend-reviewer** | Saffira Core Backend | Strict TS (no `any`), no JSDocs, decoupled IoC |
| **@saffira-admin-backend-reviewer** | Saffira Admin Backend | NestJS 11, Token IoC, `nestjs-zod` DTOs, Testcontainers |
| **@saffira-admin-frontend-reviewer** | Saffira Admin Frontend | Angular Signals, PrimeNG wrappers, `dom-testing.utils` |

---

## 📐 5-Phase Spec-Driven Architecture Pipeline

When designing new features, `@spec-master` coordinates this end-to-end multi-agent pipeline:

```mermaid
flowchart TD
    subgraph Fase 1: Descoberta & PRD Preliminar
      A[Brainstorming de Histórias] --> B[Workers coletam contexto/código]
      B --> C[Thinking Agent: PM/Analyst redige PRD com ASRs]
    end

    subgraph Fase 2: Auditoria do PRD (Review-over-PRD)
      C --> D[Subagentes Especialistas revisam viabilidade, banco, segurança e QA]
      D --> E[Thinking Agent reescreve e consolida PRD Aprovado]
    end

    subgraph Fase 3: Geração da RFC Técnica
      E --> F[Thinking Agent: Architect formula proposta técnica na RFC]
      F --> G[Workers levantam schemas, contratos e benchmarks]
      G --> H[RFC com Topologia Mermaid, Sequenciamento, Rollback e ROI]
    end

    subgraph Fase 4: Auditoria da RFC (Review-over-RFC)
      H --> I[Especialistas revisam HLD, LLD, Algoritmo, Segurança e DBA]
      I --> J[Architect resolve pendências e emite RFC Aprovada]
    end

    subgraph Fase 5: Decomposição & Handoff
      J --> K[PO/PM decompõe em Tarefas Atômicas ClickUp / Tickets]
      K --> L[Dev implementa via TDD e submete ao QA]
    end
```

---

## 🛡️ Forensic Code Review Pipeline (`skills/code-review/`)

The 11-step code review workflow guarantees zero regression and forensic thoroughness:

```markdown
# Review Progress Matrix - PR #<ID> (<REPO>)

- [ ] 1. Extração do Diff, Metadados e Comentários Anteriores dos PRs (`gh pr view --comments`)
- [ ] 2. Auditoria dos Comentários Anteriores & Prevenção de Duplicidade (De-duplication)
- [ ] 3. Despacho do Subagente de Segurança (security-reviewer)
- [ ] 4. Despacho do Subagente de Arquitetura HLD & CAP (architecture-reviewer)
- [ ] 5. Despacho do Subagente de LLD & SOLID (lld-reviewer)
- [ ] 6. Despacho do Subagente de Complexidade Algorítmica (algorithm-complexity-reviewer)
- [ ] 7. Despacho do Subagente de Frontend (angular-reviewer / saffira-admin-frontend-reviewer)
- [ ] 8. Despacho do Subagente de Backend (backend-reviewer / saffira-backend-reviewer)
- [ ] 9. Despacho do Subagente de QA & Testes (qa-reviewer)
- [ ] 10. Despacho do Subagente de Banco de Dados (dba-reviewer)
- [ ] 11. Quality Gate, Rastreabilidade PRD/RFC & Consolidação do Relatório Final
```

### Addy Osmani 5-Axis Standard & Structural Remedies
- **5 Axes:** Corretude, Legibilidade/Simplicidade, Arquitetura, Segurança e Performance.
- **Structural Remedies:** Proibir críticas vagas; prescrever a refatoração arquitetural exata (ex: substituir condicionais aninhadas por dispatchers tipados, eliminar pass-through wrappers).
- **PRD/RFC Traceability:** Tabela de conformidade mapeando requisitos (`RF`, `RNF`, `RFC §`) com status `✅ Conforme`, `⚠️ Parcial` ou `⚪ Omitido`.
- **Diagrama de Sequência & ROI:** Diagramas Mermaid destacando gaps operacionais e tabela de priorização ROI (P0 a P3).

---

## 🛑 Hardened Developer Standards (`@dev`)

- **Regra Zero:** Tolerância zero para tokens, senhas ou JWTs como fallback estático (`process.env.TOKEN || 'fallback'`). Fail-fast obrigatório.
- **Inspeção Prévia:** Inspecionar arquivos vizinhos antes de criar novos. Se o repositório separa HTML, SCSS e TS em Angular, é proibido criar templates inline.
- **Fidelidade à Versão:** Detecção estrita da versão no `package.json` sem misturar sintaxe de versões anteriores.

---

## 📂 Repository Structure

- `agents/`: Agent definitions with standard YAML frontmatter, tools, and model declarations.
- `rules/`: Global rules, constitutions, tech-presets, and templates.
- `plugs/`: Workspace Plugs (Aton corporate submodule + Personal projects).
- `skills/`: Global capabilities, QA pipelines, refactoring, and development workflows.
- `scripts/`: Automation scripts for global (`install.sh`) and project-local (`install-project.sh`) setups.
