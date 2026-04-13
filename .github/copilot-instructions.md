- **COPILOT VALIDATION & SYNCHRONIZATION MANDATE:**
  - ✅ On **every interaction**, read and validate `.github/copilot-instructions.md` (this file)
  - ✅ On **every interaction**, read `.github/SKILL.md` — the Flutter coding execution rules
  - ✅ On **every interaction**, read `docs/COPILOT_WORKSPACE_IDENTITY.md` — workspace fingerprint + terminal contingency
  - ✅ **CONFIRM READING ALL THREE FILES** at the start of each response before proceeding
  - Purpose: Ensure you and the user are synchronized on standards, patterns, and quality gates

# Copilot Instructions for devocional_nuevo — Flutter/Dart Repository

## Project Identity

- **Repo:** `develop4God/devocional_nuevo`
- **Stack:** Flutter + Dart, BLoC + custom ServiceLocator (get_it style)
- **Composition root:** `lib/services/service_locator.dart` + `lib/main.dart`
- **DI contract:** Services injected via `getService<IFoo>()` — never instantiated directly, never stored as singletons outside the locator

## Code Standards

- **Always validate code after changes:**
    - Run `flutter run` or another fast validation command to ensure the project compiles without
      errors before committing.
    - Fix any compile errors immediately.

- **Test-driven development:**
    - Always run `flutter test` before starting any task and regularly during development.
    - Fix or refactor any failing tests so all tests pass before submitting changes.

- **Keep code clean and formatted:**
    - Use `dart format .` frequently to enforce consistent code style.
    - Use `dart analyze --fatal-infos` to keep the codebase clean and resolve warnings/errors.

- **Production code must remain functional:**
    - Do not modify production code unless absolutely necessary for the requested feature or fix.
    - Any modification should be justified in the commit message and, when substantial, documented.

- **BLoC architecture guidelines:**
    - Prefer the BLoC pattern for state and business logic management.
    - For each logical group of BLoCs, create a dedicated folder (e.g., `lib/blocs/auth/`,
      `lib/blocs/devotional/`).
    - Keep business logic out of UI components; organize by feature and responsibility.

- **Dependency Injection (DI) — HARD RULES:**
    - `getService<T>()` allowed ONLY in:
      - `main.dart` — BlocProvider wiring
      - Widget `BlocProvider create:` callbacks
      - `service_locator.dart` — registration
    - `getService<T>()` is **FORBIDDEN** in:
      - BLoC event handlers
      - Service method bodies
      - Repository method bodies
      - `initState` of widgets (move to composition root)
    - Every new service MUST be registered in `setupServiceLocator()` under its **interface type**
    - Direct instantiation (`MyService()`) outside `service_locator.dart` is a **hard block**

## 🎯 SKILL.md — The Execution Framework

Before applying any change, implementing any feature, or fixing any bug, you must read `.github/SKILL.md`. 

This document defines the six-step execution process:
- **Step 0:** What files to read before touching the code
- **Step 1:** How to apply changes exactly as specified (no improvisation)
- **Step 2:** Mandatory quality gates (format → analyze → fix → test)
- **Step 3:** SOLID compliance verification
- **Step 4:** DI compliance (hard rules on `getService<T>()`, registration, direct instantiation)
- **Step 5:** Test infrastructure reuse + test coverage requirements
- **Step 6:** Report format (structured output after every task)

**SKILL.md is not optional.** Every code change follows its structure. If a task contradicts SKILL.md, flag it and ask the user for clarification.

### Mandatory Quality Gates (Step 2)

Run these in order after **every change**, before reporting done. All four must pass:

1. **Format** — `dart format lib/ test/` (Zero tolerance — unformatted code is rejected)
2. **Analyze** — `dart analyze --fatal-infos` (Target: 0 issues — fix every error, warning, and info)
3. **Fix** — `dart fix --apply` (Apply all suggested fixes, then re-run analyze)
4. **Tests** — **FOCUSED TESTING ONLY** (see critical rule below)

#### ⚠️ CRITICAL: Focused Testing Rule
- **NEVER run the full test suite** — too slow, masks issues, defeats verification
- Run ONLY focused tests on:
  - The specific test file you just created/modified
  - Existing tests directly related to the changed code (same domain/feature)
- Example: Modify `DevocionalProvider` → run only `devocional_provider_test.dart` + related widget tests
- **Exception:** Full suite only if user explicitly requests
- **Test coverage mandatory:** If no tests exist for changes → ADD tests per Step 5 requirements
- All focused tests must pass before reporting done

### SOLID Compliance Check (Step 3)

Verify your changes against these rules before reporting done:
- **S (Single Responsibility):** Each class has one reason to change
- **O (Open/Closed):** Add behavior by extending, not editing existing logic
- **L (Liskov Substitution):** Existing implementations still fulfill the contract
- **I (Interface Segregation):** No unrelated methods added to interfaces
- **D (Dependency Inversion):** Classes depend on interfaces, not concrete types

### DI Compliance Check (Step 4) — HARD RULES

| Rule | Consequence |
|---|---|
| `getService<T>()` in BLoC/Service/Repository | Hard block — fix before done |
| Direct instantiation outside locator | Hard block — fix before done |
| Service not registered in `setupServiceLocator()` | Hard block — fix before done |
| Service registered under concrete type (not interface) | Hard block — fix before done |
| `@visibleForTesting` on production code | Hard block — redesign required |
| `resetForTesting()` on production interface | Hard block — move to fake, not contract |

### Test Infrastructure (Step 5)

Before writing any test, read:
- `test/helpers/test_helpers.dart` — ServiceLocator setup
- `test/helpers/bloc_test_helper.dart` — BLoC test base classes and mocks
- `test/helpers/widget_pump_helper.dart` — Widget test utilities
- Existing test files in the same domain — reuse patterns

**Test coverage requirements:**
- New BLoC event handler → Unit test for all state transitions
- New service method → Unit test: happy path + error path + dispose safety
- New repository method → Unit test: save/load round-trip + failure case
- New widget behavior → Widget test: user action → expected UI state
- New DI registration → Entry in `test/migration/no_singleton_antipatterns_test.dart`

### Report Format (Step 6)

Always end task responses with this structure:

```
✅ Changes Applied
[File] — [what changed]

🔬 Quality Gates
- dart format: ✅ / ❌
- dart analyze --fatal-infos: ✅ / ❌
- dart fix --apply: ✅ / ❌
- flutter test: ✅ / ❌

🧱 SOLID + DI Check
✅ No violations — OR — ⚠️ [Violations listed]

🧪 Tests Added
[Test file] — [coverage] — OR — ⚠️ [Reason none added]

🚫 Flags for Architect
[Issues] — OR — None
```

## Development Workflow

- Install dependencies: `flutter pub get`
- Validate compilation: `flutter run`
- Run tests: `flutter test`
- Format code: `dart format .`
- Analyze code: `dart analyze --fatal-infos`

## ⚠️ Terminal Contingency (CRITICAL)

**Flutter subprocess commands** (e.g., `flutter test`, `flutter build`) return `null` from 
`get_terminal_output(id)` because they spawn async subprocesses that the JetBrains terminal 
can't capture.

**For Flutter commands: redirect output to file, then read the file:**

```bash
# Step 1: Run command with output redirected to file
id = run_in_terminal(
  "cd /home/develop4god/projects/devocional_nuevo && " +
  "/home/develop4god/development/flutter/bin/flutter test <file> " +
  "--reporter compact > /tmp/test_output.txt 2>&1",
  isBackground=true
)
get_terminal_output(id)  # Returns null (expected for subprocesses)

# Step 2: Read the output file after subprocess completes
id = run_in_terminal("cat /tmp/test_output.txt", isBackground=true)
get_terminal_output(id)  # Returns actual test output
```

**For direct shell commands** (echo, ls, cat, etc.), output is captured normally:

```bash
id = run_in_terminal("echo 'test' && pwd", isBackground=true)
get_terminal_output(id)  # Returns output immediately
```

For analysis/tests, use the project scripts with this pattern:

```bash
# Analyze:
bash errors.sh 2>&1; echo EXIT=$?

# Test ONE file (never run full suite — reporter crashes):
bash tests.sh test/unit/providers/devocional_provider_test.dart 2>&1; echo EXIT=$?
```

See `docs/COPILOT_WORKSPACE_IDENTITY.md` for full details.

## Guidelines

1. Keep the existing project structure and organization.
2. Write unit tests for any new functionality or bugfix.
3. Document public APIs and complex logic.
4. Update documentation in `docs/` or README.md if changes impact usage or structure.

---

**Note for Copilot:**  
Follow these instructions to maintain quality, consistency, and reliability in this repository.
