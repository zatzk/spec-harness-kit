# Zoom Out Standard 🦅 (Anti-Weeds & Simplicity Gate)

Este padrão normativo define a barra de qualidade para avaliar designs de alto nível, arquiteturas técnicas (RFCs) e propostas de refatoração sob uma perspectiva macroscópica de alta altitude.

---

## 🎯 Princípio Central

Um design ou RFC técnica é aprovado se resolve o **problema raiz** da forma mais simples e sustentável possível, reaproveita a infraestrutura e convenções existentes do repositório, evita otimizações prematuras e abstrações especulativas (**YAGNI**), e preserva limites claros de responsabilidade sem afundar em detalhes microscópicos de implementação de código ("síndrome das ervas daninhas").

---

## 🧭 Pilares de Avaliação

### 0. Suficiência de Contexto (Prerequisite Check)
* O documento deve conter informações suficientes para identificar o objetivo central e a motivação do negócio.
* Se o revisor não conseguir discernir claramente *o que* está sendo feito e *por que*, o documento é reprovado imediatamente solicitando contexto.

### 1. Foco no Problema Raiz vs Sintomas
* **Causa Raiz:** O design deve resolver a causa primária do problema, nunca aplicar paliativos ou band-aids locais.
* **Alinhamento Arquitetural:** Deve respeitar os princípios norteadores definidos na raiz do projeto (`README.md`, `ARCHITECTURE.md` ou `constitution.md`).

### 2. Simplicidade, YAGNI & Poda de Complexidade
* **YAGNI (You Aren't Gonna Need It):** Rejeitar categoricamente camadas de abstração, factories desnecessárias ou flags de configuração criadas apenas para requisitos futuros hipotéticos.
* **Anti-Otimização Prematura:** Rejeitar filas assíncronas, sharding ou caches distribuídos complexos sem evidência prévia de gargalos ou volumetria expressa nos ASRs.
* **Fluxo Minimalista de Dados:** Os dados devem trafegar pelo menor número de componentes e camadas intermediárias possível.
* **Sem Beco Sem Saída Arquitetural:** Interfaces devem ser limpas para permitir evolução futura, sem implementar agora recursos especulativos.

### 3. Controle de Altitude (Anti-Weeds / Anti-Ervas-Daninhas)
* **Proibição de Código Microscópico na Arquitetura:** As seções de topologia e contratos devem focar em limites, dados e fluxos, nunca em pseudocódigo trivial, nomes de variáveis de loops ou funções auxiliares internas.
* **Correção Estrutural vs Workaround:** Proibir workarounds mirabolantes no cliente se uma correção pontual no componente raiz/serviço central for mais limpa e definitiva.
* **Posicionamento Correto:** Garantir que a lógica resida na camada adequada da stack (ex: validação de contrato no DTO, persistência no repositório, regras no serviço).

### 4. Alavancagem do Código Existente (Leverage Existing)
* **Reuso Compulsório:** Antes de aprovar novos utilitários, wrappers ou bibliotecas, o autor deve comprovar que fez varredura no repositório (`grep`, `AST search`) e que nenhuma solução nativa existente pode ser reutilizada.
* **Consistência de Padrões:** Seguir os padrões idiomáticos já estabelecidos no projeto (ex: Signals vs RxJS em Angular, Result Pattern vs Exceptions no backend).
* **Identificação de Antipadrões:** Bloquear agressivamente padrões banidos pelo repositório (ex: bypass de autenticação, fallbacks hardcoded, dependências circulares).
