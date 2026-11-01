#!/usr/bin/env python3
"""Promptfoo Custom Provider bridging to spec-harness-kit worker-dispatch.sh.

Enforces model tiers, read-only plan mode, anti-recursion clearing, and the
Universal Scarce Frontier Guard during automated prompt evaluation.
"""

import os
from pathlib import Path
import subprocess
from typing import Any, Dict

REPO_ROOT = Path(__file__).resolve().parents[3]
DISPATCH_SCRIPT = REPO_ROOT / "scripts" / "worker-dispatch.sh"


def call_api(prompt: str, options: Dict[str, Any], context: Dict[str, Any]) -> Dict[str, Any]:
    """Execute worker-dispatch.sh with the composed prompt and return the evaluation output."""
    options_config = options.get("config", {}) if isinstance(options, dict) else {}
    context_vars = context.get("vars", {}) if isinstance(context, dict) else {}

    tier = options_config.get("tier", "standard")
    mode = "plan"  # Evaluators always enforce read-only plan mode (ASR-04)
    agent = context_vars.get("agent_name") or options_config.get("agent", "dev")
    target_cwd = options_config.get("cwd") or str(REPO_ROOT)
    timeout_sec = int(options_config.get("timeout", os.getenv("WORKER_TIMEOUT", "180")))

    # 1. Universal Scarce Frontier Guard (ASR-03)
    if tier == "frontier":
        if os.getenv("ALLOW_FRONTIER_EVAL") != "1":
            return {
                "error": (
                    "🛑 Scarce Frontier Guard Violation: Frontier tier evaluation is blocked "
                    "by default to prevent quota burnout. Set ALLOW_FRONTIER_EVAL=1 to enable."
                )
            }
        if len(prompt) > 3500:
            return {
                "error": (
                    f"🛑 Scarce Frontier Guard Violation: Prompt exceeds 3,500 chars ({len(prompt)} chars). "
                    "Pre-distill into a <= 500 word decision memo before consulting the frontier tier."
                )
            }

    if not DISPATCH_SCRIPT.exists():
        return {"error": f"Dispatcher script not found: {DISPATCH_SCRIPT}"}

    # 2. Mock mode for offline CI and contract verification
    if os.getenv("MOCK_WORKER_DISPATCH") == "1":
        if "super-secret-jwt-token" in prompt:
            return {
                "output": (
                    "### Status Geral\n"
                    "STATUS: FAIL\n\n"
                    "### 🔴 Problemas Críticos de Segurança\n"
                    "- **Arquivo:** src/auth/auth.service.ts\n"
                    "- **Linha/Trecho:** Linha 14\n"
                    "- **Vulnerabilidade:** Token JWT hardcoded e backdoor sem autenticação (bypassAuth).\n"
                    "- **Sugestão de Correção:** Carregar segredo do ConfigService e remover backdoor.\n"
                )
            }
        elif "findUserById" in prompt:
            return {
                "output": (
                    "### Status Geral\n"
                    "STATUS: PASS\n\n"
                    "### 🔴 Problemas Críticos de Segurança\n"
                    "Nenhum problema crítico de segurança identificado.\n\n"
                    "### 🟡 Recomendações e Boas Práticas de Segurança\n"
                    "- A validação de entrada está adequada.\n"
                )
            }
        elif "order-enricher" in prompt or "catalogItems.find" in prompt:
            return {
                "output": (
                    "### Status de Complexidade Algorítmica\n"
                    "STATUS: FAIL\n\n"
                    "### 🔍 Diagnóstico Algorítmico & Estruturas de Dados\n"
                    "Detectado laço aninhado com complexidade O(N * M) e chamadas sequenciais individuais ao Redis (N+1 query).\n\n"
                    "### 🖼️ Diagrama Mermaid de Complexidade / Fluxo Algorítmico (OBRIGATÓRIO)\n"
                    "```mermaid\n"
                    "flowchart TD\n"
                    "  A[Orders Loop O(N)] --> B[Catalog find O(M)]\n"
                    "  B --> C[Redis GET O(1) x N]\n"
                    "```\n\n"
                    "### 📊 Tabela Comparativa de Complexidade Assintótica & ROI\n"
                    "| Trecho / Operação | Abordagem Atual | Complexidade Atual (Tempo / Espaço) | Solução Algorítmica Proposta | Complexidade Proposta (Tempo / Espaço) | Ganhos de ROI (Latência, Escalabilidade, Memória) | Prioridade |\n"
                    "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |\n"
                    "| Busca de item | catalogItems.find | Tempo: O(N * M) | Pré-indexar em Map | Tempo: O(N + M) linear | Redução drástica para tempo linear | Alta |\n"
                    "| Cache Redis | for ... redis.get | Latência N RTTs | Batching via MGET / pipeline | Latência 1 RTT | Elimina N+1 de rede | Alta |\n"
                )
            }
        return {"output": "### Status Geral\nSTATUS: PASS\nNenhum problema identificado."}

    # 3. Prepare environment: Clear SPEC_HARNESS_WORKER so child worker starts cleanly
    env = os.environ.copy()
    env.pop("SPEC_HARNESS_WORKER", None)

    cmd = [
        str(DISPATCH_SCRIPT),
        tier,
        mode,
        agent,
        prompt,
        str(target_cwd),
    ]

    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout_sec,
            env=env,
            cwd=str(REPO_ROOT),
        )

        if proc.returncode == 0:
            return {"output": proc.stdout}

        if proc.returncode == 2:
            return {
                "error": "⚠️ Security Alert: Read-only worker violated plan mode and modified working tree state!"
            }

        return {
            "error": (
                f"Worker failed with return code {proc.returncode}:\n"
                f"STDERR: {proc.stderr.strip()}\n"
                f"STDOUT: {proc.stdout.strip()}"
            )
        }

    except subprocess.TimeoutExpired:
        return {"error": f"Worker execution timed out after {timeout_sec}s"}
    except Exception as exc:
        return {"error": f"Unexpected execution failure: {str(exc)}"}
