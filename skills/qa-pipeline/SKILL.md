---
name: qa-pipeline
description: "Pipeline completo de QA em múltiplos níveis com Scout, Lead e Revisores Especialistas (Review-over-Review)"
allowed-tools:
  - Bash
  - Read
  - Write
---

# QA Multi-Tier Pipeline (Review-over-Review)

Este workflow executa a esteira determinística de garantia de qualidade para Pull Requests ou branches de trabalho, operando em modelo **Gemini 3.8 Flash** por padrão para máxima velocidade e economia de tokens.

## Argumentos Suportados
- `<url-do-pr-ou-branch>`: Link completo do PR no GitHub ou nome da branch local.
- `--workspace=<aton|personal>`: Força a seleção do workspace plug.
- `--model=<default|deep|claude>`:
  - `default`: Gemini 3.8 Flash (padrão)
  - `deep`: Gemini 3.8 Pro / Thinking
  - `claude`: Claude 3.7 Sonnet (sob demanda)

## Roteiro de Execução em 5 Passos

### 1. Despacho do QA Scout
O `qa-scout` extrai os metadados, o diff dos arquivos e os comentários prévios do PR (`gh pr view --comments`), compilando o `Inspection Manifest` com os domínios disparados (`has_database`, `has_security`, etc.).

### 2. Resolução do Workspace Plug
Com base nas keywords do PR/branch ou do argumento `--workspace`, o orquestrador carrega o `manifest.yaml` correspondente (ex: `plugs/aton/manifest.yaml`), ativando as regras do projeto e os subagentes especialistas apropriados.

### 3. Lead First Pass (@qa)
O `@qa` analisa o manifest e os arquivos críticos aplicando o Protocolo de Inspeção em 6 Camadas, gerando o parecer técnico preliminar.

### 4. Despacho Seletivo de Especialistas (Review-over-Review)
Os subagentes especialistas avaliam o parecer preliminar do Lead juntamente com o código dos seus respectivos domínios:
- Se `has_database` -> Despacha `dba-reviewer`.
- Se `has_security` -> Despacha `security-reviewer`.
- Se `has_architecture` -> Despacha `architecture-reviewer`.
- Se `has_lld` -> Despacha `lld-reviewer`.
- Se projeto específico -> Despacha o revisor de stack (`saffira-backend-reviewer`, `saffira-admin-backend-reviewer` ou `saffira-admin-frontend-reviewer`).

### 5. Consolidação e Emissão do Relatório
O `@qa` consolida todos os apontamentos, desduplica itens já comentados no PR e gera o relatório final com `QA_SCORE` (0-100), salvando em:
`docs/code-reviews/<projeto>/<branch-ou-pr>.md`.
