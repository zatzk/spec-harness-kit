# Threat Modeling Standard (STRIDE & Trust Boundaries)

Este padrão normativo estabelece os critérios objetivos de aprovação (**Pass/Fail**) para a modelagem de ameaças e arquitetura segura durante a concepção de especificações de produtos (PRDs) e documentos técnicos (RFCs).

---

## 🎯 Objetivo

Garantir que todo novo fluxo de dados, endpoint de API, comunicação entre serviços ou manipulação de dados sensíveis possua mitigação explícita contra vetores de ataque antes do início da implementação.

---

## 🚦 Critérios Normativos de Aprovação (Pass / Fail)

Toda RFC ou PRD que introduza ou modifique serviços, endpoints ou modelos de dados deve satisfazer integralmente os 5 critérios a seguir para obter status de **Aprovado**:

### 1. Mapeamento Explícito de Trust Boundaries (Fronteiras de Confiança)
* **Requisito:** O documento deve conter um diagrama (Mermaid) identificando claramente as fronteiras de confiança entre zonas de privilégio distintas (cliente público, gateway de API, serviços internos, filas assíncronas e bancos de dados).
* **Critério de Falha:** Considerar todo o tráfego interno como "implicitamente confiável" (*perimeter-only security*) ou omitir autenticação/autorização em chamadas inter-serviços que transportam dados sensíveis.

### 2. Análise e Cobertura STRIDE Completa
* **Requisito:** A proposta técnica deve explicitar como cada vetor do framework STRIDE foi considerado e mitigado:
  - **Spoofing:** Como identidades de usuários e de serviços são autenticadas (ex: JWT assinado, mTLS).
  - **Tampering:** Como a integridade de payloads e mensagens em fila é protegida contra adulteração.
  - **Repudiation:** Como ações críticas são registradas em logs de auditoria imutáveis com rastreabilidade de ator e timestamp.
  - **Information Disclosure:** Garantia de que segredos, credenciais e PII não vazam em logs, mensagens de erro ou respostas de API desnecessárias.
  - **Denial of Service:** Mecanismos de contenção de abusos (rate limiting por IP/token, timeouts de rede, limites máximos em uploads e paginação forçada).
  - **Elevation of Privilege:** Validação de autorização (RBAC/ABAC) no lado do servidor em cada requisição, sem confiar em papéis ou flags enviados pelo cliente.
* **Critério de Falha:** Omitir mitigação de qualquer categoria STRIDE aplicável ao escopo da funcionalidade.

### 3. Proteção e Ciclo de Vida de Segredos
* **Requisito:** Nenhum segredo (tokens, chaves de API, senhas) pode constar hardcoded em documentação, variáveis estáticas ou commits. O documento deve definir a fonte confiável de injeção (ex: Secret Managers, variáveis de ambiente seguras via runtime).
* **Critério de Falha:** Prescrição de segredos estáticos ou fallbacks inseguros em tempo de execução.

### 4. Cenários de Abuso e Casos de Uso Malicioso (Abuse Cases)
* **Requisito:** A especificação deve listar pelo menos 2 cenários de uso abusivo ou malicioso de regras de negócio legítimas (ex: requisições concorrentes para duplicar transações, manipulação de IDs sequenciais em URLs) e prescrever as travas estruturais de prevenção.
* **Critério de Falha:** Assumir que o usuário ou cliente sempre seguirá o "caminho feliz" (*happy path*).

### 5. Proporcionalidade e Anti-Overengineering (KISS)
* **Requisito:** As mitigações devem ser proporcionais ao risco do sistema, priorizando mecanismos nativos de frameworks modernos (guards, middlewares de rate-limit, schemas Zod/DTOs) em vez de introduzir soluções criptográficas ou proxies customizados sem necessidade.
* **Critério de Falha:** Implementação de controles defensivos convolutos que degradem severamente a usabilidade sem ganhos mensuráveis de segurança.
