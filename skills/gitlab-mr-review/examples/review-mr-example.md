# Code Review — MR !42: Implement User Authentication

**Repositório:** `myorg/myapp`
**Autor:** dev-john
**Branch:** `feature/auth` → `main`
**Revisado em:** 2026-05-18

---

## Descrição do MR

Implementa o fluxo de login utilizando JWT e integração com o provedor de identidade. Adiciona o middleware de autenticação nas rotas protegidas.

---

## Problemas Críticos

> Itens que bloqueiam o merge.

### 1. Secret hardcoded no código

**Arquivo:** `src/config/auth.ts:15`

A chave secreta utilizada para assinar os tokens JWT está definida diretamente no código. Isso é uma vulnerabilidade grave de segurança.

**Sugestão:**
Mover a chave secreta para uma variável de ambiente (`process.env.JWT_SECRET`) e garantir que ela não seja commitada no repositório.

---

## Pontos de Melhoria

> Não bloqueiam, mas devem ser considerados.

### 1. Performance: N+1 na listagem de usuários

**Arquivo:** `src/services/userService.ts:85`

A função `listAllUsers` está fazendo uma query separada para buscar o perfil de cada usuário dentro de um loop, o que causará lentidão com muitos usuários.

**Sugestão:**
Utilizar um `JOIN` ou `eager loading` na query principal para trazer os perfis em uma única chamada ao banco de dados.

---

## O que Foi Bem Feito

- **Validação de tipos** (`src/models/user.ts:10`): Ótimo uso de Zod para validar a entrada de dados no cadastro.
- **Tratamento de Erros**: As rotas de autenticação possuem um tratamento de erro centralizado e amigável.

---

*Review gerado por Claude Code via `glab` em 2026-05-18*
