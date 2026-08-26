# PLAN_305.md — Phase-Based Startup for Devotional Data

> Reviewed by an Opus-backed architect pass against `test/chore-testing` (commit `44f0c1ec`, includes the a1197c9e fetch-timeout fix and the constants-naming refactor). One correction applied below: the architect's draft was run against a worktree that had defaulted to `origin/main` and so was missing both of those commits — it incorrectly reported `devocionalFetchTimeout` as absent. That has been fixed by rebasing the worktree onto `test/chore-testing`; the constant exists at `constants.dart:142`. The rest of the architect's findings were verified directly against the actual repo code before or during this conversation and stand as written.

## 1. Problem restatement

Five independently-tuned wall-clock timeouts gate one logical operation ("are devotionals ready?"), and none of them knows about the others:

| # | Location | Constant | Role today |
|---|---|---|---|
| 1 | `lib/main.dart:600` `_kAppStartupTimeout` | 12s (`Constants.appStartupTimeout`) | `Future.wait([...]).timeout()` around `_initCriticalServices` + `_initAppData` + min-splash |
| 2 | `lib/providers/devocional_provider.dart:284` `waitUntilLoaded()` | 30s (`Constants.devocionalProviderWaitTimeout`) | throws `TimeoutException` if `isLoading` never flips |
| 3 | `lib/providers/devocional_provider.dart:304` `waitUntilInitialized()` | 30s (same constant) | **broken** — see §2c |
| 4 | `lib/pages/devocionales_page.dart:258` retry delay | 2s (`Constants.devocionalInitRetryDelay`) | sleep, retry once, then `throw StateError('No devotionals available after initialization')` |
| 5 | `lib/repositories/devocional_repository_impl.dart:148` | 20s (`Constants.devocionalFetchTimeout`) | whole-response HTTP timeout on the ~6MB year-file GET |

Plus `Constants.indexFetchTimeout` = 3s on the index HTTP call — the one *legitimate* timeout in the system.

Cascade in the failure case: `main.dart` `_initAppData()` → `DevocionalProvider.initializeData()` → `_fetchAllDevocionalesForLanguage()` → `getAvailableYears()` (index fetch, 3s bounded) → `fetchAll(year, ...)` **per year, sequentially**, each up to a 20s-bounded ~6MB GET. Two years = up to ~12MB serial, up to 40s of allowed fetch time, racing a 12s watchdog that has no idea the fetch is even still running. The 12s watchdog fires at 12036/12009/12005 ms in Crashlytics — mid-download, aborting nothing (the `Future.wait` timeout just proceeds; the underlying `http.Client().get()` future keeps running detached, per `Future.timeout()` semantics — it doesn't cancel the socket). `devocionales_page` then finds an empty list, sleeps 2s, retries, and throws `StateError`.

**Root cause is not any single constant's value.** It's that "should I proceed to the next step" is decided by elapsed wall-clock instead of "did the prior phase actually produce its output." Confirmed nuance: `fetchAll()` returns from disk with **zero** network calls when `!isStale && hasLocal` (repository lines ~121-135), so the blast radius is fresh installs and index-bumped/stale caches only — most warm-cache launches are already fast today.

## 2. Critique of the prior plan (posted as an issue comment)

The prior plan's offline-first direction is right, but it does not fully satisfy "phases gated by completion, not timers." Specific gaps:

**2a. It keeps the timeouts, just makes them rarer.** Its step 3 said "no change needed to the 12s watchdog itself if step 2 makes `initializeData()` resolve fast whenever cache exists." That's exactly the objection: the cold-start path — the one generating the Crashlytics volume — still races a 12s wall-clock against a potentially-12MB download. A fresh install on a slow link fails identically after that change. Frequency drops; the mechanism doesn't change.

**2b. It left the 30s `waitUntilLoaded()` as an open question rather than a decision.** `waitUntilLoaded()` already has a correct event-driven core (`addListener` → check `!_isLoading` → `completer.complete()`) wrapped in a `.timeout(30s, onTimeout: throw)`. The listener *is* the phase-completion signal. The 30s should only exist as a genuinely-last-resort escape hatch, not as an expected code path.

**2c. `waitUntilInitialized()` has a live defect the prior plan didn't mention.**
```dart
Future<void> waitUntilInitialized() {
  if (_isInitialized) return Future.value();
  final completer = Completer<void>();
  void listener() {
    if (_isInitialized) {
      removeListener(listener);
      if (!completer.isCompleted) completer.complete();
    }
  }
  addListener(listener);
  return completer.future.timeout(
    Constants.devocionalProviderWaitTimeout,
    onTimeout: () => removeListener(listener),   // <-- returns void, not completer.complete()
  );
}
```
`Future<T>.timeout(duration, onTimeout: T Function())` requires `onTimeout` to *produce a value of type T* to complete the future with. Here `onTimeout` returns `void` from `removeListener`, which is not a completion of `completer.future` — for a `Future<void>`, Dart accepts the mismatched-return callback but the **returned future from `.timeout()` itself completes** with that (trivial) value; the underlying `completer.future` is separately abandoned. Net effect: any caller of `waitUntilInitialized()` on a provider that never reaches `_isInitialized` gets an *apparently normal* return after 30s with no error — silently wrong, not just slow. Needs a dedicated unit test and a fix regardless of the rest of this plan.

**2d. Stream vs. Future was framed as the central decision; it isn't.** Either shape can be made phase-driven. The real decision is *what gates navigation away from the splash* — currently `Future.wait(...).timeout(12s)`. A `Stream`-shaped repository API doesn't by itself change that gate, and it adds a subscription-lifecycle burden to `DevocionalProvider` (a `ChangeNotifier}` with no `dispose()`-time stream teardown today) for a case that only ever needs two emissions, not an open feed.

**2e. The `StateError` throw is a design problem, not a UX detail to defer.** `devocionales_page.dart` already has a `_PageInitializationState` enum (`notStarted/loading/error/ready`) with an error-rendering branch and a retry entry point. "No data available" is a legitimate terminal phase outcome, not an exception to throw-and-catch two frames later.

**2f. The index-unreachable path on a genuinely empty cache is currently undiagnosed.** If the index is unreachable, `_indexUnreachable = true` → `indexDate = null` → `isStale = false`, so `fetchAll` takes the cache branch — fine if a cache exists. On a **fresh install** with no cache and no index, it falls to the network branch using a URL built from the static `DevocionalYears.availableYears` fallback list. That path is exercised by real fresh installs and isn't called out anywhere in the original issue.

**Verdict:** keep the offline-first intent from the prior plan; replace "leave the watchdogs in place for the cold-start case" with an explicit phase machine (§3); replace the Stream-first framing with "gate on phase completion, pick emission shape per call site."

## 3. Proposed phase model

Model startup readiness as an explicit, ordered state machine where **each transition is caused by a prior phase producing a value**, and the UI renders whichever phase it's currently in. No phase advances on a timer — only individual external I/O calls (never composite phases) get a timeout, as a stuck-socket escape hatch.

### 3.1 The phases

```
                     ┌──────────────┐
                     │     idle     │   nothing started
                     └──────┬───────┘
                            │ start()
                            ▼
                     ┌───────────────┐
                     │ resolvingIndex│  index.json GET (3s bounded — external I/O)
                     └──────┬────────┘
              ┌────────────┴────────────┐
     index ok │                         │ index unreachable
              ▼                         ▼
      ┌───────────────┐        ┌───────────────────┐
      │ indexResolved │        │ indexUnavailable   │ (not terminal — cache may still serve)
      └───────┬───────┘        └─────────┬──────────┘
              └─────────────┬────────────┘
                             ▼
                   ┌──────────────────┐
                   │  checkingCache   │  per-year: hasLocal? + sidecar-vs-index date
                   └────────┬─────────┘
        ┌───────────────────┼───────────────────┐
        │ all years fresh   │ some stale/        │ no cache at all
        │                   │ missing, ≥1 usable │ AND index unavailable
        ▼                   ▼                    ▼
 ┌─────────────┐    ┌──────────────────┐   ┌──────────────────┐
 │ servingCache │    │ servingCache      │   │  needsFirstFetch │
 │  (final)     │    │ + refreshing      │   └────────┬─────────┘
 └──────┬───────┘    └────────┬──────────┘            │
        │                     │                        ▼
        │                     │              ┌──────────────────┐
        │                     │              │  fetchingYears   │ N years, progress
        │                     │              │  (foreground)    │ emitted per year
        │                     │              └────────┬─────────┘
        │                     │              ┌─────────┴─────────┐
        │                     │      ≥1 year │                   │ 0 years ok
        │                     │        ok    ▼                   ▼ + no cache
        │                     │       ┌──────────┐       ┌──────────────┐
        │                     └──────▶│ dataReady│       │  unavailable │ (terminal, retryable)
        └────────────────────────────▶│ (final)  │       └──────────────┘
                                       └──────────┘
```

Key property: **`servingCache` is reached without any network wait**, and it is a *ready* state — the splash dismisses on it. Background refresh continues and re-emits into `dataReady` with fresher content; nothing in the UI waits on it.

`needsFirstFetch → fetchingYears` is the only phase with an unavoidable foreground network wait — there is genuinely nothing to show yet. It is gated on **"year N finished"**, not elapsed time, and emits partial progress: once year 1 lands with a non-empty list, transition to `dataReady` and let year 2 finish in the background. This alone converts the worst case from "wait for ~12MB" to "wait for ~6MB," driven by a real completion signal.

### 3.2 Where this lives (SOLID + ServiceLocator compliance)

**Recommended: `DevocionalStartupBloc` (new), `lib/blocs/devocionales/`** — matches the existing `devocionales_navigation_bloc` layout and this project's BLoC+ServiceLocator convention.

- `devocional_startup_event.dart`: `StartupRequested`, `StartupRetryRequested`, plus internal events for a year landing / a phase failing.
- `devocional_startup_state.dart`: states mirroring §3.1 — `StartupIdle`, `StartupResolvingIndex`, `StartupCheckingCache`, `StartupServingCache(devocionales, refreshing: bool)`, `StartupFetching(yearsDone, yearsTotal)`, `StartupReady(devocionales)`, `StartupUnavailable(reason)`.
- Constructor takes `DevocionalRepository` **by interface**, injected from the composition root (`main.dart`'s `BlocProvider create:`, an allowed `getService<T>()` site). **No `getService<T>()` inside the BLoC itself** — hard block per this project's DI rules.
- SRP: owns *startup phase sequencing only*. Language/version resolution, favorites, audio, and filtering stay in `DevocionalProvider` — this doesn't attempt to absorb that provider's other responsibilities in the same pass.

Rejected alternative: folding the phase machine directly into `DevocionalProvider` (already ~1100 lines covering language, versions, favorites, audio delegation, invitation dialog, fetching) would deepen an existing SRP violation rather than fix one.

### 3.3 Repository changes

Add to `DevocionalRepository`, keeping `fetchAll` intact so existing callers are untouched:

```dart
Future<CacheStatus> checkCacheStatus(int year, String language, String version);
Future<List<Devocional>> readLocal(int year, String language, String version);
```

`CacheStatus` is a small value object `{bool hasLocal, bool isStale, bool indexReachable}`. This is a pure decomposition of the branching already inside `fetchAll` (repository lines ~92-135) — no new logic, just making the phase boundary observable to a caller instead of buried in one big if/else. Then `fetchAll` itself is re-expressed in terms of these two methods, so there's a single implementation of the freshness rule instead of a duplicated one.

### 3.4 What gates the splash

Replace `main.dart`'s `Future.wait([...]).timeout(_kAppStartupTimeout)` with:

```dart
await Future.wait([
  _initCriticalServices(),
  Future.delayed(_kMinSplashDisplay),
]);
await startupBloc.stream.firstWhere((s) => s.isServableOrTerminal);
```

`isServableOrTerminal` = `StartupServingCache | StartupReady | StartupUnavailable`. Each is a *real* signal: cache read completed, fetch completed, or fetch definitively failed. `_initCriticalServices()` (anonymous auth + timezone init) already swallows its own errors internally and doesn't need the shared watchdog.

## 4. Where genuine timeouts remain, and why

Timeouts survive **only** on operations crossing an external boundary that can hang forever with no completion signal at all — never on a composite of phases.

| Timeout | Value | Justification |
|---|---|---|
| `Constants.indexFetchTimeout` on `index.json` GET | 3s (keep, unchanged) | Small payload, dead-socket guard. Its failure is already non-fatal — returns `null`, phase transitions to `indexUnavailable` and continues to the cache check. Legitimate use of `Future.timeout`. |
| `Constants.devocionalFetchTimeout` on the year-file GET (repository line 148) | 20s (**reshape**, see below) | Currently a whole-response timeout — the exact capacity mismatch the issue identifies (a legitimately slow-but-alive 6MB transfer and a dead socket look identical to a fixed-duration timer). |

**How to reshape the year-file timeout without it becoming another magic number to re-tune later.** Don't use a fixed total-duration timeout on a variable-size download. Use an **idle/stall timeout**: the request only fails if *no bytes arrive* for N seconds, not if the whole transfer takes longer than N. With `package:http`'s `Client.send()` returning a `StreamedResponse`, apply `.timeout(stallWindow)` to the **byte stream**, not to the whole response future. A working-but-slow legitimate download never trips it; a dead socket trips it in N seconds regardless of file size. This also directly fixes the "timeout doesn't cancel the socket" issue noted in code review — an idle-stream timeout naturally aborts the subscription instead of leaving a detached future running.

Suggested N = 15s for the stall window — defensible from first principles (well past any reasonable inter-chunk gap on a live connection, well under a user's patience for a stuck request), not backfitted from crash telemetry. If the streaming-timeout change is judged too large for this pass, the interim fallback is to keep the current whole-response 20s timeout as-is; note explicitly that doing so re-admits the exact tension this issue is about, and track it as an immediate follow-up rather than closing the loop.

**Timeouts removed outright:**

- `_kAppStartupTimeout` (12s) — replaced by `stream.firstWhere(isServableOrTerminal)`.
- `waitUntilLoaded()`'s 30s wrapper — delete the `.timeout()`, keep the listener. Every path through `_fetchAllDevocionalesForLanguage()` and `initializeData()` already guarantees `isLoading` flips back to `false` in a `finally` block, so the timeout is dead weight once the phase machine (which removes the only source of an indefinite hang — the unbounded fetch) is in place.
- `waitUntilInitialized()`'s 30s wrapper — same rationale, and removing it also resolves the silent-hang defect in §2c as a side effect (the real fix is deleting the broken timeout path, not patching its return value).
- `Future.delayed(2s)` retry in `devocionales_page.dart` — replaced by an explicit, user-driven retry (§5). A blind 2s sleep-and-retry doesn't fix a slow network; it just issues the request twice.

Net result: five wall-clock gates become one reshaped stall-timeout (year-file GET) plus the one already-legitimate index timeout — down from effectively governing every phase transition to guarding exactly the two points where a single external HTTP call could hang forever.

## 5. Retry / error UX per phase

Principle: every phase failure is a **state the UI renders**, never a thrown exception caught elsewhere. `devocionales_page.dart` already has the `_PageInitializationState` enum, an error-rendering branch, and a retry entry point — wire the phase states into that instead of manufacturing a `StateError`.

| Phase outcome | What the user sees | Recovery |
|---|---|---|
| `resolvingIndex` (in flight) | Splash, as today | — |
| `indexUnavailable` **+ cache exists** | Nothing special — content renders from cache. Existing `_isOfflineMode` flag can drive an optional subtle offline indicator. | Auto-refreshes next launch |
| `checkingCache` / `servingCache(refreshing: true)` | Content immediately; no spinner, no blocking. Optional thin top progress bar for the background refresh. | — |
| `fetchingYears` (fresh install, foreground) | Determinate "Preparing devotionals — year 1 of 2." Real progress from a real signal, not a spinner with no basis. | Bounded by the stall timeout on the underlying GET, not by a phase-level timer |
| `unavailable` (network error) | Full-screen: "Couldn't download devotionals. Check your connection." + **Retry** button | `StartupRetryRequested` re-enters `resolvingIndex`. No sleep, no silent auto-retry. |
| `unavailable` (HTTP 4xx/5xx) | Same surface, distinct copy ("Content is temporarily unavailable"). | Retry |
| Partial success (year 1 ok, year 2 failed) | **Not** an error — `dataReady` with what loaded, plus a small dismissible banner offering a manual refresh. | Inline refresh, not a blocking retry |

Delete the `throw StateError(...)` in `devocionales_page.dart` and its associated `FirebaseCrashlytics.recordError` call. "Empty after fetch" stops being treated as an anomaly and becomes the `StartupUnavailable` state. Keep Crashlytics reporting for genuinely *unexpected* exceptions only — reporting an expected offline outcome as a non-fatal is what inflated Crashlytics issue #3 in the original report to 84 events/17 users.

## 6. Implementation steps, in order

Each step is independently mergeable and independently testable — this can land incrementally rather than as one large PR.

1. **Fix `waitUntilInitialized()`'s silent-hang defect** (§2c) — standalone bug fix, no dependency on anything else here. Either complete the completer properly on timeout or (once step 6 lands) delete the timeout wrapper entirely.
2. **Extract cache-status from `fetchAll`** — add `checkCacheStatus` + `readLocal` to the repository interface and impl; re-express `fetchAll` in terms of them. Pure refactor, no behavior change; existing repository tests must stay green throughout.
3. **Reshape the year-file timeout to a stall/idle timeout** on the byte stream (§4), replacing the current whole-response `.timeout(_fetchTimeout)`. Standalone — fixes the "timeout doesn't cancel the socket, and penalizes slow-but-alive connections" problems independent of the rest of this plan.
4. **Introduce `DevocionalStartupBloc`** with the §3.1 states, constructed with an injected `DevocionalRepository`. Not yet wired to any UI — fully unit-testable in isolation.
5. **Add per-year incremental emission** — `fetchingYears` transitions to `dataReady` after the first non-empty year lands, rather than waiting for all years. This is the change that removes the worst-case serial download wait.
6. **Wire `main.dart`** — replace `Future.wait(...).timeout(_kAppStartupTimeout)` with `stream.firstWhere(isServableOrTerminal)`; delete `_kAppStartupTimeout`. Delete the `.timeout()` wrapper on `waitUntilLoaded()` and `waitUntilInitialized()` (the fix from step 1 becomes moot once the timeout itself is gone).
7. **Wire `devocionales_page.dart`** — map startup states onto `_PageInitializationState`; delete the 2s `Future.delayed` and the `StateError` throw; render the retry surface for `unavailable`.
8. **Register in `setupServiceLocator()`** if the BLoC needs to be app-scoped (near the existing `DevocionalRepository` registration); otherwise construct at the `BlocProvider create:` site in `main.dart`. Either is an allowed `getService<T>()` location per this project's DI rules — inside the BLoC's own event handlers is not.

Steps 1 and 3 are small, standalone bug fixes that can ship ahead of the rest as an immediate follow-up to the already-committed constants-naming refactor.

## 7. Testing strategy (Gate 4 / 4b — focused runs, red-green per fix)

Focused test runs only, per this project's rule — never the full suite. Every bug fix gets a test that fails before the fix and passes after (confirmed by reverting the fix and re-running).

**Red-green, per defect:**

- `test/unit/providers/devocional_provider_test.dart` — **red**: construct a provider whose `_isInitialized` never flips within the test window; assert `waitUntilInitialized()` either throws or the test can detect it never resolved meaningfully (today it silently "succeeds" per §2c — this needs a test that would catch that, e.g. asserting a distinguishable error/marker rather than a bare successful completion). **Green** after step 1.
- `test/unit/repositories/devocional_repository_test.dart` — **red**: mock HTTP client whose byte stream emits a few bytes then never closes and never sends more; assert `fetchAll` completes (via cache fallback or a stall error) rather than hanging past a short test timeout. **Green** after step 3.

**Phase machine (steps 4-5), new `test/unit/blocs/devocional_startup_bloc_test.dart`:**
- Fresh cache, index reachable → emits `[ResolvingIndex, CheckingCache, ServingCache]`; assert the mock HTTP client recorded **zero** year-file requests.
- Stale cache → emits `ServingCache(refreshing: true)` then `Ready`; assert `ServingCache` is emitted **before** a deferred/`Completer`-controlled network mock resolves — proves the transition isn't time-based.
- No cache, index unreachable, network fails → emits `Unavailable`; assert no exception escapes the bloc.
- No cache, year 1 succeeds / year 2 fails → emits `Ready` with year-1 content, not `Unavailable`.
- `StartupRetryRequested` from `Unavailable` re-enters `ResolvingIndex`.

**Startup gate (step 6):** widget test — stub the bloc to emit `ServingCache` only after a controllable `Completer` completes; use `FakeAsync`, advance time past 12s with the completer still unresolved and assert the splash is still showing (proves nothing advances on elapsed time alone); then complete the completer and assert navigation fires immediately.

**Page states (step 7):** widget test — bloc emits `Unavailable`; assert the retry button renders and tapping it dispatches `StartupRetryRequested`; assert `FirebaseCrashlytics.recordError` is **not** called for this expected-offline path.

**Regression guard:** the existing `devocional_repository_test.dart` and `devocional_provider_test.dart` suites (24 tests confirmed passing on `test/chore-testing` as of this plan) must stay green through steps 2-3's refactor — that's the safety net for the `fetchAll` decomposition and the timeout reshape.

## Critical files for implementation

- `lib/repositories/devocional_repository_impl.dart` — `fetchAll` (~lines 87-190, the cache/network branch to decompose); line 148, the timeout to reshape
- `lib/repositories/devocional_repository.dart` — interface, add `checkCacheStatus`/`readLocal`
- `lib/providers/devocional_provider.dart` — `initializeData` (~199-268), `waitUntilLoaded` (~273-291), `waitUntilInitialized` (~293-313, the bug), `_fetchAllDevocionalesForLanguage` (~463-566)
- `lib/main.dart` — `_AppInitializerState` (~593-760), the 12s watchdog and `_initAppData`
- `lib/pages/devocionales_page.dart` — `_initializeNavigationBloc` (~209-390), `_PageInitializationState`, its render switch
- `lib/services/service_locator.dart` — registration site, near the existing `DevocionalRepository` registration
- `lib/utils/constants/constants.dart` — `devocionalFetchTimeout` (line 142, to reshape), `appStartupTimeout`/`devocionalProviderWaitTimeout`/`devocionalInitRetryDelay` (lines 146-154, to delete once their gates are removed in step 6/7)

## Explicitly out of scope

- The three unrelated Crashlytics issues from #305 (resume-watchdog black screen, FCM `SERVICE_NOT_AVAILABLE`, `libflutter.so`) — tracked separately, not touched here.
- Any change to the offline-fallback-language logic in `_fetchAllDevocionalesForLanguage()` beyond noting (§2f) that its fallback GET is also currently unbounded and should get the same stall-timeout treatment as step 3, as a follow-up.
