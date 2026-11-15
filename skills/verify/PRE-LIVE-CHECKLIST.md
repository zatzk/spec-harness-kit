# Pre-Live Security & Production Readiness Checklist

Run locally before deploying or exposing any preview/production URL (weekly cadence recommended for live apps).

1. **SQL/NoSQL Injection & Weak Auth Probe:**
   - Test exposed auth, search, and filter endpoints for injection payloads, missing JWT/session validation, and default/weak credentials.
2. **API IDOR (BOLA) & Auth Rate Limiting:**
   - Verify User A cannot read, update, or delete User B's resources by swapping path/query IDs.
   - Verify login, password-reset, and OTP endpoints enforce rate limiting / lockout.
3. **Host, Secrets & Storage Exposure:**
   - Confirm zero admin/service-role keys (`SUPABASE_SERVICE_ROLE_KEY`, private API keys) appear in client bundles or `NEXT_PUBLIC_*` / `VITE_*` / browser env.
   - Confirm object storage buckets are private by default, Row-Level Security (RLS) is enabled on multi-tenant tables, and database ports are not publicly reachable.
4. **AI / LLM Prompt-Injection Boundary:**
   - If the app processes untrusted external data (emails, web pages, user-submitted docs, PR comments) with an LLM/MCP, verify untrusted content is treated strictly as **data** (isolated/delimited) and cannot trigger privileged writes or exfiltration (**Lethal Trifecta** check).
5. **Production Readiness & Tested Backup:**
   - Confirm healthcheck, structured error logging (without leaking stack traces/secrets), and a **recently tested backup/restore** procedure.
   - **Escalation Rule:** If the app stores health, financial, legal, or core business-critical records, automated/AI checks are a baseline—require a professional human security review before launch.
