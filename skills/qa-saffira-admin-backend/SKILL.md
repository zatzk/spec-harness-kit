---
name: qa-saffira-admin-backend
description: Specific QA guidelines, testing strategies, and implementation plan for the saffira-admin/backend project.
allowed-tools:
  - "Read"
  - "Write"
---

# 🛡️ QA Saffira-Admin Backend Testing Skill

This skill provides specific testing implementation instructions for resolving gaps in the **saffira-admin/backend** project.

## 📌 Context & Scope
The implementation plan for `saffira-admin/backend` aims to elevate testing resilience in network boundaries, route-level role/tenant security guards, and asynchronous notifications/email workflows.

---

## 🛠️ Testing Blueprints

### 1. Connection Module (E2E Tests)
- **Target File:** `src/connection/tests/e2e/connection-manager.controller.e2e.spec.ts`
- **Infrastructure:** Use NestJS `Test.createTestingModule` + `@testcontainers/mongodb` + `supertest`.
- **Scenarios:**
  - **Role-Based Access Control:** Confirm only `ADMIN` or `SUPERVISOR` roles can execute write endpoints (`POST`, `PATCH`, `DELETE` on `/connection`), while `ANALYST` role yields `403 Forbidden`.
  - **Tenant Guarding (`MasterHeadquarterGuard`):** Ensure non-Master Headquarters requests are restricted and return `401` or `403`.
  - **Validation Validation (Zod Validation Pipe):** Validate bad payload payloads (invalid IPs, empty labels) yield `400 Bad Request` early.

### 2. Bucket & Storage Module (Integration Tests)
- **Target File:** `src/bucket/tests/integration/minio.repository.integration.spec.ts`
- **Infrastructure:** Real MinIO container via `@testcontainers/minio`.
- **Scenarios:**
  - **Bucket Manipulation:** Test real creation, deletion, and checks of buckets.
  - **File Stream Execution:** Real upload, download, and deletion of media files.
  - **Presigned URLs:** Verification of signed HTTP GET/PUT links with expiry intervals and CDN URL replacement.
  - **MIME-Type Resolution:** Confirm correct mapping of extensions (like `.mp4`, `.png`, `.jpg`) to correct MIME-types.

### 3. Notifications Module (Unit Tests)
- **Target File:** `src/notifications/tests/unit/telegram-notification.service.spec.ts`
- **Infrastructure:** Network mocks using global `fetch` or `undici`.
- **Scenarios:**
  - **URL Composition:** Confirm correct construction of: `https://api.telegram.org/bot<TELEGRAM_BOT_KEY>/sendMessage`.
  - **Payload Validation:** Verify JSON payload contains expected fields (`chat_id`, `text`, `parse_mode`).
  - **Missing Param Handling:** Verify service terminates gracefully and logs warnings if tokens/ids are missing.
  - **Exception Resiliency:** Ensure network request errors do not fail the thread, but are caught and sent to the logger.

### 4. Email Reset Flows (Unit Tests)
- **Target File:** `src/email/tests/unit/email-reset-flow.spec.ts`
- **Scenarios:**
  - **Template Interpolation:** Verify compilation of username/reset link tags inside email body templates.
  - **Token Lifecycle:** Validate token expiration validation and single-use constraints.

---

## 🏃 Verification Command Cheat Sheet
```bash
# Run all tests
pnpm test

# Run Connection E2E tests specifically
pnpm vitest run src/connection/tests/e2e/connection-manager.controller.e2e.spec.ts

# Run MinIO Storage integration tests
pnpm vitest run src/bucket/tests/integration/minio.repository.integration.spec.ts

# Run Telegram unit tests
pnpm vitest run src/notifications/tests/unit/telegram-notification.service.spec.ts
```
