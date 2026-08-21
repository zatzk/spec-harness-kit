---
name: gitlab-mr-review
description: >
  Realiza code review aprofundado de um Merge Request do GitLab. Recebe um link de MR como parâmetro,
  busca o diff e a descrição via CLI do glab, aplica o Protocolo de Inspeção em 6 Camadas (DIP, failure-path tracing,
  auditoria de testes e SOLID) e gera um relatório detalhado.
  Use quando o usuário pedir para revisar um MR, fazer code review de um merge request,
  ou usar /gitlab-mr-review com um link do GitLab.
argument-hint: <url-do-mr>
allowed-tools:
  - Bash
  - Write
  - Read
---

# GitLab MR Code Review

## Argumento recebido

`$ARGUMENTS`

O argumento é o link completo do MR, ex: `https://gitlab.com/grupo/projeto/-/merge_requests/42`

## O que fazer

Analisar um Merge Request do GitLab usando a CLI `glab` e produzir um relatório de code review
de alta precisão seguindo o **Protocolo de Inspeção em 6 Camadas**.

## Pré-requisitos

A variável de ambiente `GLAB_PERSONAL_TOKEN` deve estar disponível no sistema. O `glab` a usa
automaticamente como token de autenticação quando configurada.

## Passos

### 1. Extrair repo e ID do MR a partir do link

O link passado pelo usuário tem o formato:
```
https://gitlab.com/grupo/projeto/-/merge_requests/123
https://gitlab.example.com/namespace/subgroup/projeto/-/merge_requests/456
```

- O **repo** é tudo entre o host e `/-/merge_requests/`, no formato `namespace/projeto` ou
  `grupo/subgrupo/projeto`.
- O **ID** é o número após `/merge_requests/`.

Exemplo: `https://gitlab.com/myorg/myapp/-/merge_requests/42` → repo=`myorg/myapp`, id=`42`

### 2. Coletar dados do MR (execute em paralelo)

```bash
# Detalhes e descrição do MR em JSON
GLAB_TOKEN=$GLAB_PERSONAL_TOKEN glab mr view <id> --repo <repo> --output json

# Diff completo do MR
GLAB_TOKEN=$GLAB_PERSONAL_TOKEN glab mr diff <id> --repo <repo> --color=never
```

Se `GLAB_PERSONAL_TOKEN` já está no ambiente, apenas `glab mr view` sem o prefixo também funciona.

### 3. Aplicar o Protocolo de Inspeção em 6 Camadas

Não faça uma análise superficial ou apenas no *happy path*. Aplique sistematicamente:

#### 🔬 Camada 1: Rastreamento Semântico e Caminhos de Falha (*Failure-Path Tracing*)
- Inspecione cada bloco `try/catch`, interceptor ou chamada assíncrona/API externa:
  - *O que é retornado no `catch` ou fallback em caso de erro/timeout?*
  - *O tipo retornado quebra a assinatura declarada do método?* (Ex: retornar `string` com mensagem de erro em método tipado como `Promise<T[]>`).
  - *Como o código consumidor a jusante reage a esse retorno de erro?* (Ex: iterar sobre caracteres de string achando que é array).

#### 🏛️ Camada 2: Inversão de Dependência (DIP) & Composition Root
- Verifique acoplamentos rígidos: classes de serviço não devem instanciar diretamente suas dependências auxiliares (`new SubService(...)`) dentro de construtores ou métodos.
- Todas as dependências devem ser injetadas via construtor e instanciadas em **Factories** ou módulos de injeção dedicados.

#### 🛡️ Camada 3: Auditoria da Suíte de Testes (*QA Test Audit*)
- **Mocks Tautológicos:** Identifique se os testes apenas espelham os mocks sem validar regras reais (ex: repositórios usando `mockDeep` em vez de in-memory DB).
- **Abuso de `as any` em Stubs:** Verifique se mocks de repositório usam casts permissivos que mascaram quebras de contrato de tipo.
- **Testes E2E sem I/O real:** Testes classificados como E2E que utilizam stubs de rede manuais (`vi.fn()`) em vez de handshakes reais.
- **Cobertura Baseada em Valor (*Value Coverage*):** Aponte lacunas em regras algorítmicas críticas, limiares numéricos e caminhos de fallback não cobertos por testes unitários dedicados.

#### 📐 Camada 4: Tipagem Estrita & Regras do Harness Arquitetural
- **Eliminação de `any`:** Substitua `any` por tipos explícitos, tuplas estritas ou `unknown` com narrowing.
- **Regras de Estilo do Repositório:** Verifique se regras do harness foram violadas (ex: proibição de blocos JSDoc redundantes quando TypeScript já tipa parâmetros e retorno).
- **Gestão de Recursos & Concorrência:** Cheque vazamento de memória em subscrições RxJS (`takeUntilDestroyed`), timeouts não cancelados, race conditions em filas e locks assíncronos.

#### 📊 Camada 5: Complexidade Ciclomática e Princípios SOLID
- Produza a matriz estruturada avaliando cada arquivo modificado nos 5 princípios **S-O-L-I-D** e alertando sobre pontos de alta complexidade ciclomática.

#### 🟢 Camada 6: Pontos Fortes e Destaques Positivos
- Reconheça boas abstrações, funções puras determinísticas, desacoplamento por portas e adaptadores e cobertura de testes de alto valor.

### 4. Gerar o Relatório Estruturado

Gere o relatório seguindo rigorosamente a estrutura padrão abaixo.

## Formato do arquivo de saída / Review

```markdown
# Code Review — MR !<id>: <título do MR>

### 1. Resumo do Merge Request

> [!NOTE]
> - **MR:** !<id> - <título>
> - **Autor:** <autor>
> - **Repositório:** `<repo>`
> - **Branch:** `<source_branch>` → `<target_branch>`
> - **Objetivo Geral:** <resumo conciso do objetivo e arquitetura proposta>

---

### 2. 🔴 Problemas Críticos Encontrados

> Itens que bloqueiam o merge (Bugs de runtime, Quebra de contratos de tipo, Violações graves de DIP, Falhas silenciosas).

#### <Título do Problema Crítico>

No arquivo `caminho/arquivo.ts:linha`, <descrição precisa do problema>:

```typescript
// Trecho de código problemático
```

**Impacto:**
1. <Impacto técnico 1>
2. <Impacto técnico 2>

**Correção sugerida:**
<Código corrigido com injeção/tipagem adequada>

---

### 3. 🟡 Pontos de Melhoria

> Não bloqueiam imediatamente, mas devem ser considerados (Uso de `any`, violação de regras do harness/JSDoc, concorrência, lacunas de testes unitários).

#### <Título do Ponto de Melhoria>

No arquivo `caminho/arquivo.ts:linha`:
- <explicação do ponto de melhoria>

**Correção sugerida:**
<como melhorar com exemplo de código>

---

### 4. 🛡️ Relatório de Auditoria de QA (QA Test Audit)

## 📊 Resumo Executivo da Auditoria
> <Análise crítica sobre a fidelidade e valor dos testes>

## 🔴 Pontos Críticos e Falsa Sensação de Segurança
> [!CAUTION]
> **[Arquivo: caminho/teste.spec.ts] - <Problema de Teste / Mock Tautológico>**
> <Explicação detalhada de como o teste mascara falhas reais>

## 🟡 Anti-patterns de Teste Identificados
> [!WARNING]
> **[Arquivo: caminho/teste.spec.ts] - <Anti-pattern>**
> <Descrição do anti-pattern (ex: fake socket em teste E2E)>

## 📊 Cobertura Baseada em Valor (Value Coverage Report)

| Módulo | Criticidade do Módulo (1-5) | Tipos de Teste Existentes | Testa Isolamento de Inquilino? | Valor Real Gerado pelos Testes | Lacunas de Cobertura / Recomendações |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **<Nome do Módulo>** | 🔥 5/5 | Unitário Puro | Sim/Não/NA | **Alto / Médio / Baixo** | <Recomendações> |

## ⚡ Lacunas de Cobertura de Alto Valor
> [!TIP]
> 1. **<Módulo>:** <Cenários de borda e matrizes de teste que devem ser adicionados>

---

### 5. 📊 Análise de Complexidade Ciclomática e Princípios SOLID

| Arquivo | Complexidade Ciclomática (CC) | SOLID S | SOLID O | SOLID L | SOLID I | SOLID D | Diagnóstico |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `caminho/arquivo.ts` | **<CC>** | ✅ | ✅ | ✅ | ✅ | ❌/✅ | <Diagnóstico objetivo> |

---

### 6. 🟢 Pontos Positivos

- **<Boas práticas / Destaques>:** <Explicação do porquê agrega valor>
```

## Observações importantes

- **Zero tolerância para superficialidade:** Não aprove um MR apenas porque a suíte de testes passou. Mocks e testes unitários fracos frequentemente mascaram quebras de tipo e bugs de runtime.
- **Rastreie caminhos de exceção:** A maioria dos bugs críticos em produção ocorre em caminhos de fallback e blocos `catch`.
- **Seja cirúrgico e construtivo:** Sempre forneça o trecho exato de código sugerido para correção.
