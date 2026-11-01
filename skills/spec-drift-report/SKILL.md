---
name: spec-drift-report
description: Audits checked-in technical RFCs, specs, and design documents against the actual codebase to detect implementation drift, missing features, incomplete schemas, and architectural divergences.
allowed-tools: [Bash, Read, Glob, Grep, Write]
user-invocable: true
---

# 🔍 SPEC-DRIFT-REPORT: Auditoria de Divergência Spec vs Código

Esta skill realiza auditoria contínua entre as especificações técnicas aprovadas (RFCs, PRDs e documentos em `docs/designs/`, `docs/rfcs/`, `rfcs/`) e a implementação real no código-fonte, detectando o apodrecimento (*drift*) da arquitetura.

---

## 🎯 Objetivo & Casos de Uso

* **Pós-Implementação:** Verificar se a implementação do `@dev` cobriu 100% dos requisitos estipulados na RFC.
* **Manutenção Periódica:** Detectar se refatorações subsequentes quebraram contratos ou introduziram atalhos que violam as decisões de arquitetura.
* **Auditoria de Conformidade:** Garantir que o repositório mantém living specifications confiáveis para futuros agentes e desenvolvedores.

---

## 🧭 Vetores de Detecção de Drift

Ao comparar uma especificação contra o código-fonte, a skill audita especificamente 4 vetores:

1. **🔴 Funcionalidades Ausentes (Missing Features):**
   * Lógica de negócio, endpoints, rotas ou tratamentos de exceção descritos na especificação mas completamente ausentes no código-fonte.
2. **🟡 Modelos & Schemas Incompletos (Incomplete Models/Schemas):**
   * Structs, entidades de banco, DTOs, interfaces TypeScript ou protos com campos, validações ou tipos diferentes do planejado na RFC.
3. **🔴 Atalhos & Fallbacks Indevidos (Logic Shortcuts & Banned Fallbacks):**
   * Valores hardcoded, mocks deixados para trás em código produtivo, ou violação do princípio de *Zero-Hardcoded-Fallbacks*.
4. **🟡 Divergência Arquitetural (Architectural Divergence):**
   * Código implementado utilizando bibliotecas, drivers ou padrões de concorrência/comunicação diferentes dos aprovados na RFC (ex: uso de polling onde foi especificado SSE/WebSocket, ou bypass de injeção de dependência).

---

## 🚀 Fluxo de Execução

### Passo 1: Mapeamento de Documentos Alvo
1. Identifique o diretório de especificações técnicas do projeto. Se o usuário não informar um caminho, inspecione:
   * `docs/designs/`
   * `docs/rfcs/`
   * `rfcs/`
   * `specs/`
   * `docs/spec/`
2. Liste todos os arquivos Markdown (`.md`) presentes no diretório alvo.

### Passo 2: Análise Individual de Cada Especificação
Para CADA documento de design encontrado:

1. **Leitura e Extração de Entidades:**
   * Leia a RFC/spec e liste os símbolos, contratos, classes, interfaces, endpoints HTTP, eventos e arquivos mencionados.
2. **Mapeamento no Código-Fonte:**
   * Utilize `grep`, `glob` ou busca semântica para localizar os arquivos correspondentes na árvore de código do repositório.
3. **Comparação Forense:**
   * Leia o estado atual dos arquivos de código localizados.
   * Compare os contratos prometidos vs a implementação real.
   * Filtre e reporte **APENAS as diferenças**. Não gere ruído descrevendo o que está conforme. Se o código estiver em total conformidade com a especificação, registre `"No drift detected"`.

### Passo 3: Emissão do Relatório de Drift
Gere o relatório na raiz do workspace ou em `docs/reports/` com o nome `{YYYY-MM-DD}_SPEC_DRIFT_REPORT.md` seguindo o formato:

```markdown
# 🔍 Relatório de Divergência Arquitetural (Spec vs Código)
**Data:** YYYY-MM-DD
**Diretório Auditado:** `<caminho_das_specs>`

---

## Resumo Executivo
* **Total de Especificações Auditadas:** X
* **Especificações Sincronizadas (Sem Drift):** Y
* **Especificações com Divergência:** Z

---

## Detalhamento por Especificação

### 📄 `<NOME_DA_RFC_OU_SPEC>.md`
* **Status:** [🔴 DIVERGÊNCIA CRÍTICA | 🟡 DIVERGÊNCIA MODERADA | 🟢 SINCRONIZADO]
* **Arquivos do Código Relacionados:** `src/path/to/file.ts`, `src/path/to/dto.ts`

#### Discrepâncias Encontradas:
* **[Missing Feature]** O endpoint `POST /api/v1/auth/refresh` descrito na Seção 3.2 não foi encontrado nas rotas de `auth.controller.ts`.
* **[Incomplete Schema]** O DTO `CreateUserDto` omite o campo obrigatório `tenantId: string` especificado na Seção 4.1.
* **[Architectural Divergence]** A RFC especificava mensageria via RabbitMQ, mas o serviço foi implementado com chamada HTTP síncrona.

#### Ações Recomendadas:
1. `src/modules/auth/auth.controller.ts`: Implementar o endpoint ausente conforme contrato.
2. `src/modules/users/dto/create-user.dto.ts`: Adicionar validação Zod para `tenantId`.
```

---

## 🛑 Invariantes de Execução

1. **Somente Leitura no Código:** Esta skill nunca altera o código funcional diretamente; seu papel é puramente de diagnóstico e emissão de relatório.
2. **Evidência Obrigatória:** Cada drift reportado deve citar o arquivo e linha da RFC e o arquivo correspondente no código-fonte.
