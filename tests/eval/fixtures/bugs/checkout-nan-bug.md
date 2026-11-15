# Bug Report: Checkout total returns NaN when coupon code has trailing whitespace

## Observed Symptom
Submitting `POST /api/checkout` with `{ "coupon": "SAVE10 " }` returns `500 Internal Server Error` and `total: NaN` in `src/services/checkout.service.ts`.

## Task
Diagnose and fix this bug following `@dev` mandatory rules. Outline your exact first execution steps before editing any production file.
