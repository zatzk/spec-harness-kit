# Re-Implementation Standard 🔄 (The Zero-Assumption Rule)

Este padrão normativo define a barra de qualidade para documentar contratos de arquitetura e pacotes de código no SPEC-HARNESS-KIT.

---

## 🎯 Princípio Central

Um documento de arquitetura ou especificação de pacote é aprovado se um engenheiro experiente ou agente autônomo for capaz de **reescrever uma implementação funcionalmente idêntica na primeira tentativa** utilizando exclusivamente as instruções do documento, sem adivinhar e sem fazer escolhas arquiteturais independentes.

---

## 🛑 A Regra da Suposição Zero (The Zero-Assumption Rule)

O documento **FALHA automaticamente** se o leitor precisar:
* Adivinhar parâmetros default ou comportamentos não documentados;
* Supor estratégias de tratamento de erro ou fallbacks;
* Inferir o formato ou schema de saída das operações;
* Escolher padrões de concorrência ou consistência não definidos.

Todo contrato com significância comportamental observável deve ser explícito.

---

## 📦 Escopo de Detalhe Contratual

### O que DEVE ser incluído:
* **Contratos Externos:** Assinaturas de APIs, rotas, tipos de retorno, códigos de status HTTP, headers e side effects em banco/disco.
* **Invariantes e Regras de Negócio:** Validações de entrada, pré-condições, pós-condições e transições de estado.
* **Restrições de Desempenho e Recursos:** Limites de concorrência, timeouts, taxas de throttling e ordens de complexidade Big-O toleradas.
* **Efeitos Colaterais:** Emissão de eventos, persistência em filas, métricas geradas e logs estruturados emitidos.

### O que NÃO deve poluir o documento:
* Detalhes microscópicos de sintaxe interna (nomes de variáveis temporárias em loops);
* Funções privadas puramente cosméticas;
* Estruturas de coleções internas que não afetam os contratos observáveis da interface pública.
