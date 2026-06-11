---
name: qa-saffira-backend
description: QA guidelines, audit findings, and refactoring patterns specifically for the saffira/backend codebase.
allowed-tools:
  - "Read"
  - "Write"
---

# 🛡️ QA Saffira Backend Audit & Refactoring Skill

This skill contains specific guidelines and blueprints to fix critical test architecture flaws identified in the **saffira/backend** project audit.

## 📌 Scope & Findings
The audit report for `saffira/backend` highlighted key gaps:
- **Tautological Mocks:** Excessive use of `mockDeep` on Mongoose models.
- **Tenant Isolation:** Absence of multi-tenancy verification tests.
- **Instability:** Hardcoded `setTimeout` delays in async/socket tests.
- **Direct Seeding:** Seeding database records directly (bypassing model lifecycles/hooks).
- **Compromised Types:** Overuse of TypeScript `as any` casts.

---

## 🛠️ Refactoring Blueprints

### A. Replacing Mocks with Real DB (mongodb-memory-server)
Instead of mocking the database layer (which prevents verifying schema rules and query compatibility), use `mongodb-memory-server` in repository unit/integration tests:

*Example for `occurrence.repository.test.ts`:*
```typescript
import { MongoMemoryServer } from "mongodb-memory-server";
import mongoose from "mongoose";
import { OccurrenceRepository } from "../../repositories/occurrence.repository";

describe("OccurrenceRepository (Real Memory DB Integration)", () => {
  let repository: OccurrenceRepository;
  let mongod: MongoMemoryServer;

  beforeAll(async () => {
    mongod = await MongoMemoryServer.create();
    await mongoose.connect(mongod.getUri());
  });

  beforeEach(async () => {
    await mongoose.connection.collection("ocorrencias").deleteMany({});
    repository = new OccurrenceRepository();
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongod.stop();
  });

  it("should validate schemas and persist an occurrence", async () => {
    const result = await repository.create(mockOccurrenceData);
    expect(result._id).toBeDefined();
    
    const persisted = await mongoose.connection
      .collection("ocorrencias")
      .findOne({ _id: result._id });
    expect(persisted).not.toBeNull();
  });
});
```
*Apply this pattern to:*
- `occurrence.repository.test.ts`
- `personnel.repository.test.ts`
- `locals.repository.test.ts`
- `ImagesRepository.test.ts`

### B. Correcting Async Waiting with `vi.waitFor`
Replace hardcoded `setTimeout` delays in socket and job routines with deterministic polling:

*Example for `VehiclesJob.e2e.test.ts`:*
```typescript
import { vi } from "vitest";

it("returns status via socket deterministically", async () => {
  await vehicleJob.routine();

  await vi.waitFor(() => {
    expect(
      socketRegister.getAllClientsByRoute(vehiclesEndpoints.socket)![0].emit
    ).toHaveBeenCalledWith("veiculo:status", fakeVehiclesList());
  }, {
    timeout: 1000,
    interval: 50,
  });
});
```
*Apply this pattern to:*
- `SocketListenAlarms.e2e.test.ts`
- `VehiclesJob.e2e.test.ts`

### C. Seeding via Repositories (No Bypass)
Never seed testing databases using raw driver statements like `mongoose.connection.collection("ocorrencias").insertMany(...)`. Use the actual repository methods or properly typed factory functions so validation rules and lifecycle hooks (`pre-save`, etc.) are triggered.

---

## 🏃 Target Test Commands
```bash
# Run backend tests
npm run test

# Target specific repository tests
npm run test src/features/occurrences/tests/unit/occurrence.repository.test.ts
```
