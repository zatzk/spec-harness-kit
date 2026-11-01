# Heilmeier Catechism Standard 🏛️

Este padrão normativo define a barra de qualidade para propostas de novos projetos, épicos e PRDs no ecossistema SPEC-HARNESS-KIT, adaptado do clássico *Heilmeier Catechism* (DARPA).

---

## 🎯 Princípio Central

Uma proposta ou PRD preliminar é aprovada se e somente se um engenheiro ou agente recém-iniciado (com zero contexto prévio da equipe) conseguir compreender os objetivos, riscos, restrições e valor entregue, confirmando que todas as 8 perguntas do catecismo foram respondidas de forma inequívoca e sem jargões desnecessários.

---

## 📋 Perguntas Obrigatórias do Catecismo (The 8 Questions)

Para atingir conformidade com este padrão, o documento deve responder explicitamente:

1. **Objetivos (Objectives):**
   * *O que está sendo tentado?*
   * Deve ser formulado em linguagem direta, clara e livre de jargões corporativos ou acrônimos não explicados.

2. **Estado da Arte Atual (State of the Art):**
   * *Como isso é resolvido hoje no sistema ou na indústria?*
   * Quais são os limites estruturais, gargalos e dores da prática atual?

3. **Nova Abordagem (New Approach):**
   * *O que há de novo na proposta e por que acreditamos que terá sucesso?*
   * Qual é o diferencial técnico ou funcional em relação às tentativas anteriores?

4. **Impacto & Usuários (Impact):**
   * *Quem se importa? Se formos bem-sucedidos, qual diferença mensurável isso fará para o negócio e para o usuário final?*

5. **Riscos & Compensações (Risks & Payoffs):**
   * *Quais são os principais riscos arquiteturais, de segurança e de negócio?*
   * Quais são os payoffs esperados para justificar assumir esses riscos?

6. **Custos & Recursos (Cost):**
   * *Quanto custará em termos de compute, infraestrutura, complexidade operacional e tokens de IA?*

7. **Cronograma & Fases (Timeline):**
   * *Qual é a decomposição em etapas e a estimativa de entrega atômica?*

8. **Exames de Validação & Métricas (Metrics & Exams):**
   * *Quais são os "exames" intermediários e finais para comprovar o sucesso objetivo da solução antes e depois do deploy?*

---

## 🛑 Critério de Reprovação Automática

Qualquer proposta que omita mais de uma dessas dimensões ou responda com generalismos sem embasamento empírico deve ser reprovada com o status:
`REPROVADO: Falha no Heilmeier Catechism Standard (Questões pendentes: [X, Y])`.
