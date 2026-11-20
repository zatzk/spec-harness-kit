---
name: qa-pipeline
description: "Pipeline completo de QA em múltiplos níveis com Scout, Lead e Revisores Especialistas (Review-over-Review)"
allowed-tools:
  - Bash
  - Read
  - Write
---

# QA Multi-Tier Pipeline (Review-over-Review)

Este workflow executa a esteira determinística de garantia de qualidade para Pull Requests ou branches de trabalho. A seleção de modelo é delegada ao roteador de decisão (Jev), que escolhe o tier conforme a complexidade — este workflow não fixa modelo.

## Argumentos Suportados
- `<url-do-pr-ou-branch>`: Link completo do PR no GitHub ou nome da branch local.
- `--workspace=<aton|personal>`: Força a seleção do workspace plug.

## Roteiro de Execução em 5 Passos

### 1. Despacho do QA Scout
O `qa-scout` (despachado com `Model: "flash_lite"`/`"flash"` ou `spec-worker-dispatch cheap plan`) extrai os metadados, o diff dos arquivos e os comentários prévios do PR (`gh pr view --comments`), compilando o `Inspection Manifest` com os domínios disparados (`has_database`, `has_security`, etc.).

### 2. Resolução do Workspace Plug
Com base nas keywords do PR/branch ou do argumento `--workspace`, o orquestrador carrega o `manifest.yaml` correspondente (ex: `plugs/aton/manifest.yaml`), ativando as regras do projeto e os subagentes especialistas apropriados.

### 3. Lead First Pass (@qa)
O `@qa` analisa o manifest e os arquivos críticos aplicando o Protocolo de Inspeção em 6 Camadas, gerando o parecer técnico preliminar.

### 4. Despacho Seletivo de Especialistas (Review-over-Review)
Os subagentes especialistas avaliam o parecer preliminar do Lead juntamente com o código dos seus respectivos domínios (passando `Model` explícito em `invoke_subagent`):
- Se `has_database` -> Despacha `dba-reviewer` (`Model: "flash"` ou `"pro"`).
- Se `has_security` -> Despacha `security-reviewer` (`Model: "pro"`).
- Se `has_architecture` -> Despacha `architecture-reviewer` (`Model: "pro"`).
- Se `has_lld` -> Despacha `lld-reviewer` (`Model: "flash"` ou `"inherit"`).
- Se projeto específico -> Despacha o revisor de stack (`saffira-backend-reviewer`, `saffira-admin-backend-reviewer` ou `saffira-admin-frontend-reviewer`, `Model: "flash"` ou `"inherit"`).

### 5. Consolidação e Emissão do Relatório
O `@qa` consolida todos os apontamentos, desduplica itens já comentados no PR e gera o relatório final com `QA_SCORE` (0-100), salvando em:
`docs/code-reviews/<projeto>/<branch-ou-pr>.md`.

### 6. Anti-Death-Loop Gate (Convergence Rule)
- **Limite de Ciclos:** Máximo de **2 ciclos** de revisão → correção por PR/branch.
- **Critério de Convergência:** Assim que `P0 = 0` e `P1 = 0`, apontamentos estilísticos ou menores (`P2`/`P3`) devem ser registrados como follow-ups não-bloqueantes e o pipeline **DEVE** emitir aprovação (`PASS`), evitando loops infinitos de nitpicking adversarial.
