---
name: gitlab-mr-review
description: >
  Realiza code review de um Merge Request do GitLab. Recebe um link de MR como parâmetro,
  busca o diff e a descrição via CLI do glab, analisa o código e gera um arquivo markdown
  com Problemas Críticos, Pontos de Melhoria e O que Foi Bem Feito.
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
estruturado em formato markdown.

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
Tente primeiro sem o prefixo; se falhar com erro de autenticação, use `GLAB_TOKEN=$GLAB_PERSONAL_TOKEN`.

Se o glab retornar erro de repo não encontrado, tente com a URL completa via `--repo`:
```bash
glab mr view <id> --repo "https://gitlab.com/grupo/projeto"
```

### 3. Analisar o conteúdo

Com os dados coletados, analise:

**Da descrição do MR:**
- Qual é o objetivo da mudança?
- Há contexto de negócio ou decisões de design explicadas?
- O que deveria ser testado está descrito?

**Do diff:**
- Lógica incorreta ou com bugs óbvios
- Violações de segurança (SQL injection, XSS, secrets hardcoded, dados sensíveis expostos)
- Problemas de performance (N+1 queries, loops ineficientes, falta de índices)
- Tratamento de erros ausente ou inadequado em boundaries do sistema
- Código que viola contratos de tipos ou invariantes
- Melhorias de legibilidade e manutenibilidade (nomes, estrutura, complexidade desnecessária)
- Testes ausentes para lógica de negócio relevante
- Padrões do projeto que não estão sendo seguidos
- Pontos positivos: boas abstrações, código limpo, boas práticas aplicadas

### 4. Estruturar o relatório

Organize os achados em três categorias:

**Problemas Críticos** — qualquer coisa que *bloquearia* o merge:
- Bugs que causariam comportamento errado em produção
- Vulnerabilidades de segurança
- Quebra de contrato de API ou regressões funcionais
- Erros que causariam falhas em runtime

**Pontos de Melhoria** — não bloqueiam, mas deveriam ser endereçados:
- Performance subótima
- Código difícil de manter
- Testes faltando para casos importantes
- Padrões do projeto não seguidos
- Alternativas de design mais adequadas

**O que Foi Bem Feito** — reforço positivo genuíno:
- Boas abstrações introduzidas
- Código particularmente legível ou bem estruturado
- Casos de borda bem tratados
- Testes bem escritos
- Refatorações limpas

### 5. Gerar o arquivo de saída

Salve o relatório em `~/Aton/saffira-docs/review-mr-<id>.md` com o formato abaixo.

Se não houver nada em alguma categoria, escreva `> Nenhum item identificado.` na seção.

Para cada item, inclua:
- Uma linha de título em negrito descrevendo o problema/ponto
- O arquivo e número de linha quando aplicável: `` `caminho/arquivo.ts:42` ``
- Uma explicação objetiva do porquê é um problema ou ponto positivo
- Para problemas críticos e melhorias: uma sugestão concreta de como resolver

## Formato do arquivo de saída

```markdown
# Code Review — MR !<id>: <título do MR>

**Repositório:** `<repo>`
**Autor:** <autor>
**Branch:** `<source_branch>` → `<target_branch>`
**Revisado em:** <data>

---

## Descrição do MR

<descrição resumida do MR ou "Sem descrição." se vazia>

---

## Problemas Críticos

> Itens que bloqueiam o merge.

### 1. <título do problema>

**Arquivo:** `caminho/arquivo.ts:42`

<explicação objetiva do problema>

**Sugestão:**
<o que fazer para corrigir>

---

## Pontos de Melhoria

> Não bloqueiam, mas devem ser considerados.

### 1. <título>

**Arquivo:** `caminho/arquivo.ts:10`

<explicação>

**Sugestão:**
<como melhorar>

---

## O que Foi Bem Feito

- **<título>** (`arquivo.ts:5`): <por que é um ponto positivo>
- **<título>**: <explicação>

---

*Review gerado por Claude Code via `glab` em <data>*
```

## Observações importantes

- Foque em problemas reais: prefira zero falsos positivos a cobertura máxima
- Contextualize pela descrição do MR: se o autor explicou uma decisão de design, não critique sem considerar o contexto
- Seja específico: "linha 42 do arquivo X faz Y quando deveria fazer Z" é mais útil que "há um problema aqui"
- Separe opinião de fato: use "considere" para preferências estilísticas, seja direto para bugs reais
- Se o diff for muito grande (>1000 linhas), foque nos arquivos de lógica de negócio (services, controllers, domain) e mencione que arquivos de infraestrutura/config foram omitidos da análise detalhada
