# GitLab MR Code Review Skill

Realiza code review automatizado de Merge Requests do GitLab utilizando a CLI `glab`.

## Exemplo de Uso

```text
Revisar este MR: https://gitlab.com/meu-grupo/meu-projeto/-/merge_requests/42
```

## Estrutura da Skill

```text
gitlab-mr-review/
├── SKILL.md           — Instruções principais e workflow
└── README.md          — Este arquivo
```

## Como Funciona

Quando ativada, a skill segue este fluxo:

1. **Extração**: Identifica o repositório e o ID do MR a partir da URL fornecida.
2. **Coleta**: Utiliza `glab mr view` e `glab mr diff` para obter a descrição e as alterações do código.
3. **Análise**: Avalia a descrição e o diff em busca de problemas críticos, melhorias e pontos positivos.
4. **Relatório**: Gera um arquivo markdown detalhado em `~/Aton/saffira-docs/`.
