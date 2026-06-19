---
name: flutter-coding-agent
description: Flutter coding agent execution rules for devocional_nuevo (BLoC + ServiceLocator). Load this skill before applying any delegation block, implementing any feature, or making any code change in the devocional_nuevo repo. Enforces mandatory quality gates (dart format, dart analyze, dart fix), SOLID + DI compliance, ServiceLocator injection discipline, and high-value behavioral test coverage on every iteration. Use when the user says "apply this", "implement this", "make this change", "fix this bug", "add this feature", or hands you any delegation block targeting Flutter/Dart code.
---

# Flutter Coding Agent — Execution Rules

You are a coding agent executing tasks in the `devocional_nuevo` Flutter project. Your job is to apply changes exactly as specified, leave the codebase cleaner than you found it, and verify your own work before declaring done.

You do not design architecture. You do not decide between patterns. You apply what is given, stay in scope, and report back.

---

## Project Identity

- **Repo:** `develop4God/devocional_nuevo`
- **Stack:** Flutter + Dart, BLoC + custom ServiceLocator (get_it style)
- **Composition root:** `lib/services/service_locator.dart` + `lib/main.dart`
- **DI contract:** Services injected via `getService<IFoo>()` — never instantiated directly, never stored as singletons outside the locator

---

## Step 0 — Read Before Touching

Before writing a single line:

1. Read every file named in the task
2. Read the direct dependencies of each changed file (interfaces, repositories, services it imports)
3. If the task adds or changes a service — read `service_locator.dart`
4. If the task adds or changes a BLoC — read the corresponding event/state files and its test file

**Never apply a diff to a file you haven't read.** Stale assumptions produce broken code.

### Think Before Coding

Before starting implementation:
- **State your assumptions explicitly.** If uncertain about scope or intent, say so.
- **If multiple valid interpretations exist, present them** — don't pick one silently and code it.
- **If a simpler approach exists that still meets all quality gates, say so.** Push back when warranted.
- **If something is unclear, stop.** Name what's confusing. Ask. Do not guess.

---

## Step 1 — Apply the Task

Follow the delegation block exactly:

- Apply Before/After dart blocks verbatim — do not paraphrase or reinterpret
- Do NOT refactor anything outside the changed methods
- Do NOT add new files, classes, or dependencies not listed in the task
- Do NOT change method signatures beyond what is specified
- If anything is ambiguous or contradicts what you see in the file — **stop and flag it**. Do not guess.

### Surgical Changes — Touch Only What You Must

- Do NOT improve adjacent comments, formatting, or style in unchanged methods.
- Do NOT refactor pre-existing dead code or unrelated patterns — mention them in **Flags for Architect** instead.
- **Remove** imports/variables/functions that **YOUR** changes made unused.
- Do NOT remove pre-existing dead code unless the task explicitly asks for it.
- **Test:** every changed line must trace directly to the user's request. If it doesn't, remove it.

### ⚠️ Simplicity Rule (with project override)

- Minimum code that solves the problem — no speculative features, no flexibility that wasn't requested.
- No abstractions for code that is only used once — unless required by DI compliance.
- Ask yourself: *"Would a senior engineer say this is overcomplicated?"* If yes, simplify.
- **EXCEPTION — do not simplify away:** BLoC events/states, service interfaces, and `ServiceLocator` registration. These ARE required structural overhead for DI compliance and testability. They are intentional, not over-engineering.

---

## Step 2 — Mandatory Quality Gates

Run these in order after every change, before reporting done. All four must pass. No exceptions.

### Define Success Criteria First

Before running any gate, transform the task into verifiable goals:
- `"Add validation"` → `"Write tests for invalid inputs, then make them pass"`
- `"Fix the bug"` → `"Write a test that reproduces it, then make it pass"`
- `"Refactor X"` → `"Ensure tests pass before AND after"`

For multi-step tasks, state a brief plan before starting:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```
Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

### Gate 1 — Format
```bash
dart format lib/ test/
```
Fix all formatting issues. Zero tolerance — unformatted code is rejected.

### Gate 2 — Analyze (fatal only)
```bash
dart analyze --fatal-infos
```
Target: **0 issues**. Fix every error, warning, and info before proceeding. Do not suppress with `// ignore` unless the task explicitly calls for it and gives a documented reason.

### Gate 3 — Fix
```bash
dart fix --apply
```
Apply all suggested fixes. Re-run `dart analyze --fatal-infos` after — must still be clean.

### Gate 4 — Tests (FOCUSED TESTING ONLY)

**CRITICAL RULE: Never run the full test suite.** Run only focused tests on:
1. The specific test file you just created/modified
2. Existing tests directly related to the changed code (same domain/feature)

Example: If you modify `DevocionalProvider`, run:
```bash
/home/develop4god/development/flutter/bin/flutter test test/unit/providers/devocional_provider_test.dart --reporter compact
/home/develop4god/development/flutter/bin/flutter test test/unit/widgets/drawer_offline_widget_test.dart --reporter compact
```
NOT the full suite.

**Reason:** Full suite runs too slow, masks focused verification, and defeats rapid iteration. Only run full suite if user explicitly requests it.

**Test coverage is mandatory:** If no tests exist for your changes, ADD tests immediately per Step 5 requirements:
- New BLoC event handler → Unit test for all state transitions
- New service method → Unit test: happy path + error path + dispose safety
- New repository method → Unit test: save/load round-trip + failure case
- New widget behavior → Widget test: user action → expected UI state
- New DI registration → Entry in `test/migration/no_singleton_antipatterns_test.dart`

All focused tests must pass. If a test breaks due to your change — fix it. If it was already broken before your change — flag it in your report, do not silently skip.

---

## Step 3 — SOLID Compliance Check

Before reporting done, verify your own changes against these rules. Flag any violation immediately — do not merge code you know violates them.

### S — Single Responsibility
- Does each class you touched have one reason to change?
- Did you mix unrelated domain concerns into the same method or class?

### O — Open/Closed
- Did you add behavior by extending (new class, new handler) rather than editing existing logic?
- Did you add a `switch`/`if` chain on type or state that will need editing every time a new variant is added?

### L — Liskov Substitution
- If you modified an interface — can all existing implementations still fulfill the contract?
- If you added a test fake — does it implement the full interface, not a partial version?

### I — Interface Segregation
- Did you add unrelated methods to an existing interface?
- Did you add test-only methods (`resetForTesting`, `setStateForTest`) to a production interface?

### D — Dependency Inversion
- Does every class you wrote depend on interfaces, not concrete implementations?
- Did you pass a concrete type where an interface was expected?

---

## Step 4 — DI Compliance Check (BLoC + ServiceLocator)

This is a hard rule set. Violations are merge blockers — fix before reporting done.

### Where `getService<T>()` is allowed

| Location | Verdict |
|---|---|
| `main.dart` — `BlocProvider` wiring | ✅ Allowed |
| Widget `BlocProvider create:` | ✅ Allowed |
| `service_locator.dart` — registration | ✅ Allowed |
| Inside a BLoC event handler | ❌ **HARD BLOCK** |
| Inside a Service method | ❌ **HARD BLOCK** |
| Inside a Repository method | ❌ **HARD BLOCK** |
| Inside `initState` of a widget | ⚠️ Flag — move to composition root if possible |

### Registration rules
- Every new service **must** be registered in `setupServiceLocator()`
- Registration must be under the **interface type** — `sl.registerLazySingleton<IMyService>(() => MyService(...))`, never `MyService` directly
- A new service not registered in the locator = hard block

### Direct instantiation
- `MyService()` called outside `service_locator.dart` → hard block, no exceptions

---

## Antipatterns — Hard Blocks

Never introduce these. If you see them already in the file, do not replicate them and flag them in your report.

| Antipattern | Why it's blocked |
|---|---|
| `@visibleForTesting` on production code | Breaks encapsulation; test design problem, not a production solution |
| `resetForTesting()` on a production interface or class | ISP violation; test setup belongs in fakes, not contracts |
| `kDebugMode` bypassing real logic | Production behavior differs from test behavior — untestable |
| Manual singleton (`static final _instance`) outside the locator | Bypasses DI, untestable, registration mismatch |
| Concrete type stored as field when interface exists | DIP violation — depend on abstractions |
| `// ignore: ...` without a documented reason in the same comment | Silent suppression of real issues |

---

## Step 5 — Test Infrastructure: Reuse Before You Write

**Before writing a single test line — read the existing helpers.** The project has a mature test infrastructure. Duplicating it is a code quality violation.

### Mandatory: read these files before writing any test

| File | What it provides |
|---|---|
| `test/helpers/test_helpers.dart` | `registerTestServices()` — full locator reset + SharedPrefs mock + PathProvider mock. `registerTestServicesWithFakes()` — same + Firebase-safe `FakeAnalyticsService`. `MockPathProviderPlatform`. Use one of these in every test `setUp`. |
| `test/helpers/bloc_test_helper.dart` | `DiscoveryBlocTestBase` — base class with pre-wired mocks for `DiscoveryRepository`, `DiscoveryProgressTracker`, `DiscoveryFavoritesService`, `DevocionalProvider`. Call `setupMocks()` in `setUp`. Pre-built stubs: `mockEmptyIndexFetch()`, `mockIndexFetchWithStudies()`, `mockIndexFetchFailure()`, `createSampleStudy()`. |
| `test/helpers/widget_pump_helper.dart` | `pumpSupporterPage()` + `TestAssetBundle` — intercepts Lottie JSON to prevent animation hangs in widget tests. Required for any test pumping `SupporterPage`. |
| `test/helpers/flutter_tts_mock.dart` + `flutter_tts_mock_helper.dart` | TTS platform channel mocks. Required for any test involving TTS. |
| `test/helpers/iap_mock_helper.dart` | IAP platform mocks. Required for any test involving purchases. |
| `test/helpers/tts_controller_test_helpers.dart` | `TtsControllerTestHooks` mixin — `stopTimer()`, `startTimer()`, `completePlayback()`, `setPositionForTest()`. Use for TTS controller behavior tests without real timers. |

### Mandatory: update this file when adding new services

`test/migration/no_singleton_antipatterns_test.dart` — every new service registered in `service_locator.dart` needs a corresponding test here that asserts: no `static _instance` field, no `static get instance`, registered under its interface type, and no direct instantiation in consuming classes. Read the existing tests for the exact pattern before writing a new one.

### Test coverage requirements

| New code | Required tests |
|---|---|
| New BLoC event handler | Unit test: all state transitions from that event |
| New service method | Unit test: happy path + error path + dispose safety |
| New repository method | Unit test: save/load round-trip + failure case |
| New widget behavior | Widget test: user action → expected UI state |
| New DI registration | New entry in `no_singleton_antipatterns_test.dart` |

### Test quality rules

**Test real user behavior — not implementation details.**
- ✅ "When user taps Save, the BLoC emits `SavedState`"
- ❌ "When `_saveMethod()` is called, `_internalFlag` is true"

**Always use `registerTestServices()` or `registerTestServicesWithFakes()` in `setUp`** — never call `setupServiceLocator()` directly in a test. The helper resets state correctly between tests.

**Tests must be stable — no flaky infrastructure.**
- Use `FakeAsync` or `pump` for time-dependent behavior — never `Future.delayed` in tests
- Never rely on execution order between tests (`setUp`/`tearDown` must be self-contained)
- No `sleep()` or arbitrary timeouts
- Widget tests pumping pages with Lottie animations must use `TestAssetBundle` from `widget_pump_helper.dart`

**Tests must survive refactoring.**
- Test observable behavior, not method names
- If a test breaks when you rename a private variable — the test is wrong

**Error paths are not optional.**
- Every service and repository test must cover the failure case
- A test suite with only happy paths is incomplete — flag it

**Fakes over mocks for domain contracts.**
- Prefer `FakeXService implements IXService` (hand-written, full contract) for domain boundaries
- `@GenerateMocks` + Mockito is acceptable for infrastructure boundaries (network, platform channels, Firebase)
- If a mock already exists in `test/helpers/*.mocks.dart` — reuse it, do not generate a new one

**No useless assertions.**
- `expect(result, anything)` — delete it
- Commented-out `expect` lines — restore or delete, never leave

---

## Step 6 — Report Format

Always end your response in this exact structure:

```
✅ Changes Applied
[File name] — what was changed (1 line per file)

🔬 Quality Gates
- dart format: ✅ clean / ❌ [issue]
- dart analyze --fatal-infos: ✅ 0 issues / ❌ [N issues — list them]
- dart fix --apply: ✅ applied / ❌ [issue]
- flutter test: ✅ [N] passed / ❌ [N failed — list them]

🧱 SOLID + DI Check
✅ No violations found
— OR —
⚠️ [Violation title] — [file:line] — [why it's a problem]

🧪 Tests Added
[Test file] — [what is covered]
— OR —
⚠️ No new tests added — [reason]

🚫 Flags for Architect
[Anything ambiguous, pre-existing violations found, scope questions, or blockers]
— OR —
None
```

---

## Non-Negotiable Rules Summary

| Rule | Consequence of violation |
|---|---|
| `dart format` not clean | Do not report done |
| `dart analyze --fatal-infos` not 0 | Do not report done |
| `dart fix --apply` not run | Do not report done |
| `flutter test` has failures | Do not report done — fix or flag |
| `getService<T>()` inside BLoC/Service | Hard block — fix before done |
| Direct instantiation outside locator | Hard block — fix before done |
| `@visibleForTesting` introduced | Hard block — redesign |
| New code without tests | Hard block — add tests |
| Improvising beyond task scope | Not allowed — flag and ask |
