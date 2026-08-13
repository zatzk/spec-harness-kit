---
name: quality-gate
description: Playbook for setting up and running quantitative quality gates, including line/branch coverage, cyclomatic complexity, class/method size metrics, and mutation testing with ratcheting across multiple tech stacks.
allowed-tools:
  - "Read"
  - "Write"
  - "Run"
---

# Quality Gates and Mutation Testing Playbook

This skill provides step-by-step guidance on setting up and running automated **Quality Gates** and **Mutation Testing** in a project using SPEC-HARNESS-KIT. 

AI code generation is fast but prone to logical blind spots, code bloating, and superficial testing (tests that execute code but assert nothing). Quality gates act as a quantitative "fence" that code must clear before it can be committed or pushed.

---

## 📐 Core Quality Gate Pillars

A standard quality gate validates the codebase along four metrics:

| Metric | Target | Focus | Tools by Language |
| :--- | :--- | :--- | :--- |
| **Test Coverage** | Line $\ge 95\%$, Branch $\ge 90\%$ | Execution path verification | `SimpleCov` (Ruby), `Vitest/Jest/c8` (JS/TS), `go test -cover` (Go) |
| **Complexity** | Cyclomatic $\le 6$, ABC/Flog $\le 20$ | Logic readability & density | `RuboCop/Flog` (Ruby), `ESLint` (JS/TS), `gocognit/gocyclo` (Go) |
| **Module Size** | Class length $\le 100$ lines, Method length $\le 15$ | Single Responsibility Principle | `RuboCop` (Ruby), `ESLint` (JS/TS), `golangci-lint` (Go) |
| **Mutation Testing** | **Kill Ratio $\ge$ Ratchet Baseline** | Assertion check quality | `Mutant` (Ruby), `Stryker Mutator` (JS/TS), `go-mutesting` (Go) |

---

## 🔄 The Ratchet Philosophy

Forcing a legacy or active codebase to hit $90\%$ mutation kill ratios or perfect coverage immediately is often unrealistic. Instead, implement a **ratchet mechanism**:
1. Run the quality gate metrics for the first time.
2. Save the resulting scores into a local config file (e.g., `config/quality_thresholds.json` or `.yaml`).
3. For all future runs, the command checks the current metrics against the config.
4. **Pass condition:** The current score must be $\ge$ the threshold.
5. **Ratchet condition:** If the current score improves, write the new, higher score to the config file (ratchet up).
6. **Fail condition:** If the score decreases, exit with a non-zero code.

---

## 🛠 Tech Stack Setup Guides

### 1. JavaScript & TypeScript (Active Preset: `nextjs-react`)

TypeScript projects should use **Stryker Mutator** for mutation testing, **Vitest/Jest** for branch coverage, and **ESLint** for complexity metrics.

#### A. Install Dependencies
```bash
npm install --save-dev @stryker-mutator/core @stryker-mutator/typescript-runner @stryker-mutator/vitest-runner eslint-plugin-sonarjs eslint-plugin-complexity
```

#### B. Configure ESLint (Complexity & Size Limits)
Add to `.eslintrc.json`:
```json
{
  "rules": {
    "complexity": ["error", 6],
    "max-lines-per-function": ["warn", { "max": 15, "skipBlankLines": true, "skipComments": true }],
    "max-lines": ["error", { "max": 100, "skipBlankLines": true, "skipComments": true }]
  }
}
```

#### C. Configure Stryker (`stryker.config.json`)
```json
{
  "$schema": "https://schema.stryker-mutator.io/stryker-config.schema.json",
  "packageManager": "npm",
  "reporters": ["html", "clear-text", "json"],
  "testRunner": "vitest",
  "coverageAnalysis": "perTest",
  "tsconfigFile": "tsconfig.json",
  "mutate": [
    "src/**/*.ts",
    "src/**/*.tsx",
    "!src/**/*.test.ts",
    "!src/**/*.test.tsx",
    "!src/**/__mocks__/**/*.ts"
  ],
  "thresholds": {
    "high": 80,
    "low": 60,
    "break": null
  }
}
```

---

### 2. Go (Golang)

Go uses standard test coverage features, `gocognit`/`gocyclo` for complexity, and `go-mutesting` for mutation testing.

#### A. Install Quality Checkers
```bash
go install github.com/uudashr/gocognit/cmd/gocognit@latest
go install github.com/zimmski/go-mutesting/...@latest
```

#### B. Run Coverage & Complexity Checks
```bash
# Branch/Line Coverage (Go defaults to block coverage)
go test -coverprofile=coverage.out ./...
go tool cover -func=coverage.out

# Complexity Check
gocognit -over 6 .
```

#### C. Run Mutation Testing
```bash
go-mutesting ./...
```

---

### 3. Ruby

Ruby uses `SimpleCov` for branch coverage, `RuboCop` + `Flog` for complexity, and `Mutant` for mutation testing.

#### A. Install Gems
Add to `Gemfile`:
```ruby
gem "simplecov", require: false, group: :test
gem "flog", require: false, group: :test
gem "mutant-rspec", require: false, group: :test
```

#### B. Setup SimpleCov (`spec/spec_helper.rb`)
```ruby
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch
  add_filter "/spec/"
end
```

#### C. Run Mutant Command
```bash
bundle exec mutant run --integration rspec --use-opt-in-features --use-opensource -- MyNamespace::MyClass
```

---

## 📝 Running the Quality Gate

To run the quality gate, implement a quality script (e.g., `scripts/quality-gate.js` or `bin/rake quality`). 

Below is a Node.js template for `scripts/quality-gate.js` that parses test coverage reports, ESLint results, and Stryker JSON reports, verifying them against a local `config/quality_thresholds.json` ratchet config:

```javascript
#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const THRESHOLD_PATH = path.join(__dirname, '../config/quality_thresholds.json');
const STRYKER_REPORT_PATH = path.join(__dirname, '../reports/mutation/mutation.json');
const LCOV_PATH = path.join(__dirname, '../coverage/lcov.info');

// Load Current Thresholds (Ratchet)
let thresholds = { lineCoverage: 95.0, branchCoverage: 90.0, mutationKillRatio: 60.0 };
if (fs.existsSync(THRESHOLD_PATH)) {
  thresholds = JSON.parse(fs.readFileSync(THRESHOLD_PATH, 'utf-8'));
}

// 1. Run Tests and ESLint
console.log("Running Lint and Test Suite...");
execSync("npm run lint && npm run test:coverage", { stdio: 'inherit' });

// Parse Coverage (Simplified Example)
const coverage = parseLcov(LCOV_PATH); 
console.log(`Coverage: Line ${coverage.line}%, Branch ${coverage.branch}%`);

// 2. Run Mutation Tests
console.log("Running Mutation Tests...");
try {
  execSync("npx stryker run", { stdio: 'inherit' });
} catch (e) {
  // Stryker exits non-zero if mutants survive or fail. We catch and check JSON report instead.
}

const strykerReport = JSON.parse(fs.readFileSync(STRYKER_REPORT_PATH, 'utf-8'));
const mutationKillRatio = calculateStrykerKillRatio(strykerReport);
console.log(`Mutation Kill Ratio: ${mutationKillRatio}%`);

// 3. Evaluate Gates
let failed = false;

if (coverage.line < thresholds.lineCoverage) {
  console.error(`❌ Line coverage too low: ${coverage.line}% < ${thresholds.lineCoverage}%`);
  failed = true;
}
if (coverage.branch < thresholds.branchCoverage) {
  console.error(`❌ Branch coverage too low: ${coverage.branch}% < ${thresholds.branchCoverage}%`);
  failed = true;
}
if (mutationKillRatio < thresholds.mutationKillRatio) {
  console.error(`❌ Mutation kill ratio dropped: ${mutationKillRatio}% < ${thresholds.mutationKillRatio}%`);
  failed = true;
}

if (failed) {
  process.exit(1);
}

// 4. Update Ratchet if metrics improved
let updated = false;
if (coverage.line > thresholds.lineCoverage) { thresholds.lineCoverage = coverage.line; updated = true; }
if (coverage.branch > thresholds.branchCoverage) { thresholds.branchCoverage = coverage.branch; updated = true; }
if (mutationKillRatio > thresholds.mutationKillRatio) { thresholds.mutationKillRatio = mutationKillRatio; updated = true; }

if (updated) {
  fs.writeFileSync(THRESHOLD_PATH, JSON.stringify(thresholds, null, 2));
  console.log("📈 Quality thresholds ratcheted up!");
}

console.log("✅ All quality gates passed!");
```

---

## 🤖 Agent Instructions for Quality Gates

When this skill is active, agents must:
1. **Never ship untested code.**
2. **Execute the local quality script** (`npm run quality`, `go test`, or equivalent) before marking any ticket, story, or PR as complete.
3. **Include the quality results table** directly in their final response. Example:
   ```
   Quality Gates
   =============
   Line coverage:       96.5%   (Threshold: 95.0%)  [PASS]
   Branch coverage:     92.1%   (Threshold: 90.0%)  [PASS]
   Mutation Kill Ratio: 71.4%   (Threshold: 70.0%)  [PASS]
   ESLint Complexity:   Passed                      [PASS]
   ```
4. If a gate fails, the agent must fix the code or write additional tests to cover the surviving mutations or branch cases.
