---
name: github-pr-review
description: >
  Realiza code review de um Pull Request do GitHub. Recebe um link de PR como parâmetro,
  busca o diff e a descrição via CLI do gh, analisa o código e gera um arquivo markdown
  com Problemas Críticos, Pontos de Melhoria e O que Foi Bem Feito.
  Use quando o usuário pedir para revisar um PR, fazer code review de um pull request,
  ou usar /github-pr-review com um link do GitHub.
argument-hint: <url-do-pr>
allowed-tools:
  - Bash
  - Write
  - Read
---

# GitHub PR Code Review

## Argumento recebido

`$ARGUMENTS`

O argumento é o link completo do PR, ex: `https://github.com/owner/repo/pull/42`

## O que fazer

Analisar um Pull Request do GitHub usando a CLI `gh` e produzir um relatório de code review
estruturado em formato markdown.

## Pré-requisitos

A CLI `gh` deve estar instalada e autenticada. A variável de ambiente `GITHUB_TOKEN` ou um login prévio (`gh auth status`) deve estar configurado para acesso ao repositório.

## Passos

### 1. Extrair repo e ID do PR a partir do link

O link passado pelo usuário tem o formato:
```
https://github.com/owner/repo/pull/123
```

- O **repo** é tudo entre `github.com/` e `/pull/`, no formato `owner/repo`.
- O **ID** é o número após `/pull/`.

Exemplo: `https://github.com/myorg/myapp/pull/42` → repo=`myorg/myapp`, id=`42`

### 2. Coletar dados do PR (execute em paralelo)

```bash
# Detalhes e descrição do PR em JSON
gh pr view <id> --repo <repo> --json title,body,author,state,baseRefName,headRefName

# Diff completo do PR
gh pr diff <id> --repo <repo> --color=never
```

Se o gh retornar erro de repo não encontrado, verifique a autenticação ou o link do repositório.

### 3. Analisar o conteúdo

Com os dados coletados, analise:

**Da descrição do PR:**
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

Salve o relatório em `~/Aton/saffira-docs/review-pr-<id>.md` com o formato abaixo.

Se não houver nada em alguma categoria, escreva `> Nenhum item identificado.` na seção.

Para cada item, inclua:
- Uma linha de título em negrito descrevendo o problema/ponto
- O arquivo e número de linha quando aplicável: `` `caminho/arquivo.ts:42` ``
- Uma explicação objetiva do porquê é um problema ou ponto positivo
- Para problemas críticos e melhorias: uma sugestão concreta de como resolver

## Formato do arquivo de saída

```markdown
# Code Review — PR #<id>: <título do PR>

**Repositório:** `<repo>`
**Autor:** <autor>
**Branch:** `<headRefName>` → `<baseRefName>`
**Revisado em:** <data>

---

## Descrição do PR

<descrição resumida do PR ou "Sem descrição." se vazia>

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
```

## Observações importantes

- Foque em problemas reais: prefira zero falsos positivos a cobertura máxima
- Contextualize pela descrição do PR: se o autor explicou uma decisão de design, não clique sem considerar o contexto
- Seja específico: "linha 42 do arquivo X faz Y quando deveria fazer Z" é mais útil que "há um problema aqui"
- Separe opinião de fato: use "considere" para preferências estilísticas, seja direto para bugs reais
- Se o diff for muito grande (>1000 linhas), foque nos arquivos de lógica de negócio (services, controllers, domain) e mencione que arquivos de infraestrutura/config foram omitidos da análise detalhada
