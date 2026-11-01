# Implementation Readiness Standard 🎯 (The Zero-Decision Rule)

Este padrão normativo define a barra de qualidade para planos de implementação detalhados, decomposição de tarefas e handoffs de especificações técnicas para os desenvolvedores (`@dev`).

---

## 🎯 Princípio Central

Um plano de implementação é aprovado se e somente se um engenheiro competente ou agente autônomo (com zero contexto da discussão anterior) conseguir executar o plano e produzir as mudanças corretas **na primeira tentativa**, sem adivinhar, sem fazer perguntas de esclarecimento e sem tomar decisões arquiteturais independentes.

---

## 🛑 A Regra da Decisão Zero (The Zero-Decision Rule)

O plano deve deixar **ZERO escolhas arquiteturais ou de design para o desenvolvedor**.
Se o desenvolvedor precisar tomar decisões arquiteturais por conta própria — incluindo, mas não limitado a:
* Escolher ou alterar schemas de banco de dados e migrações;
* Definir rotas, métodos HTTP ou paths de endpoints de API;
* Selecionar bibliotecas, drivers ou dependências externas;
* Arbitrar contratos de DTOs ou nomes de campos essenciais;
* Escolher estratégias de recuperação de erros em cenários de borda;

O plano **FALHA imediatamente neste padrão**. Todas essas decisões devem estar pré-determinadas, acordadas e explicitadas no documento antes do handoff de implementação.

---

## 🧱 Fatiamento em Etapas & Checkpoints Compiláveis

1. **Atomicidade e Estabilidade:** O plano deve particionar o trabalho em fases incrementais e lógicas. Cada fase deve deixar o repositório em um estado estável, compilável e testável.
2. **Escopo Alvo Explícito:** O plano deve listar expressamente:
   * Arquivos a serem **Criados** (com caminho completo no repositório);
   * Arquivos a serem **Modificados** (com símbolos e funções alvo explicitados);
   * Arquivos a serem **Deletados** ou descontinuados.
3. **Plano de Testes Vinculado:** Para cada etapa, devem ser informados os casos de teste específicos (happy path e edge cases) que comprovam que a etapa atingiu o critério de aceitação.
