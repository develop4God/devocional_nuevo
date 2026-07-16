# OnboardingBloc Refactor — Concurrency Approach Review

Scope: this document covers only the concurrency-control piece of the larger
OnboardingBloc → OnboardingService SOLID refactor (dead-code removal and
method relocation sections are unchanged and already agreed). It exists to
document why the originally proposed `droppable()` approach was rejected in
favor of a service-owned write queue, for architect sign-off before
implementation.

## Current state (as of `lib/blocs/onboarding/onboarding_bloc.dart`)

Four concurrency primitives live in the bloc today:

```dart
// Race condition protection
bool _isProcessingStep = false;
bool _isCompletingOnboarding = false;
bool _isSavingConfiguration = false;

// SharedPreferences operation mutex
static bool _isSharedPrefsOperation = false;
```

- `_isProcessingStep` / `_isCompletingOnboarding` — per-handler reentrancy
  guards on `_onProgressToStep` and `_onCompleteOnboarding`. If the handler
  is already running, a duplicate dispatch is dropped (`return` early).
- `_isSavingConfiguration` + static `_isSharedPrefsOperation` — a hand-rolled
  busy-wait mutex around `_saveConfiguration()` and `_saveProgress()`:

```dart
Future<void> _saveConfiguration(Map<String, dynamic> configuration) async {
  if (_isSavingConfiguration) return; // skip if already saving

  while (_isSharedPrefsOperation) {
    await Future.delayed(const Duration(milliseconds: 10)); // busy-wait
  }

  _isSavingConfiguration = true;
  _isSharedPrefsOperation = true;
  try {
    // ... write to SharedPreferences
  } finally {
    _isSavingConfiguration = false;
    _isSharedPrefsOperation = false;
  }
}
```

`_saveProgress()` repeats the same `while (_isSharedPrefsOperation) { ... }`
busy-wait pattern, serializing itself against `_saveConfiguration` via the
**shared static flag** — this is the one piece of real cross-method
coordination in the mutex mess.

## Option A (originally proposed): `bloc_concurrency` + `droppable()`

```dart
on<ProgressToStep>(_onProgressToStep, transformer: droppable());
on<CompleteOnboarding>(_onCompleteOnboarding, transformer: droppable());
```

Delete the 4 flags, add `bloc_concurrency` to `pubspec.yaml`.

### Why this was rejected

1. **New dependency for a 4-boolean problem.** `pubspec.yaml` currently
   depends on `flutter_bloc: ^9.1.1` and `bloc_test: ^10.0.0` only —
   `bloc_concurrency` is not present anywhere in the codebase. Pulling in a
   package to replace ~10 lines of boolean bookkeeping doesn't clear the
   "minimum code that solves the problem" bar.
2. **`droppable()` doesn't cover what the static mutex actually protects.**
   `droppable()` operates on the *event stream for one event type* — it
   drops a `ProgressToStep` event if a previous `ProgressToStep` handler is
   still running. It does **not** serialize `_saveConfiguration()` against
   `_saveProgress()`, which is exactly what `_isSharedPrefsOperation` does
   today (it's a single static flag shared by both methods, i.e.
   cross-method, not per-event-type). Swapping in `droppable()` silently
   drops that cross-method guarantee rather than replacing it.
3. **It doesn't address the root cause.** The mutex exists because
   SharedPreferences writes aren't inherently safe under concurrent access
   from within the bloc. `droppable()` treats the symptom (duplicate bloc
   events) — it does nothing for a hypothetical future caller of
   `saveConfiguration()`/`saveProgress()` from outside an event handler,
   because the safety would live in the wrong layer.
4. **Wrong owner (SRP).** Per the broader refactor, persistence logic is
   moving to `OnboardingService`. Write-safety for SharedPreferences access
   is a persistence concern, not a bloc-orchestration concern — it belongs
   with the class that owns the writes, not bolted onto the class that
   dispatches events.

## Option B (proposed): serialize writes inside `OnboardingService`

Once `saveConfiguration()` / `saveProgress()` move into `OnboardingService`
per the agreed plan, give the service a single chained-future write queue:

```dart
class OnboardingService {
  // ... existing fields ...

  Future<void>? _writeQueue;

  /// Serializes SharedPreferences writes so concurrent saveConfiguration()/
  /// saveProgress() calls don't interleave. Replaces the bloc's former
  /// busy-wait mutex (_isSharedPrefsOperation) — same guarantee, no polling.
  Future<T> _serialized<T>(Future<T> Function() operation) {
    final previous = _writeQueue ?? Future.value();
    final result = previous.then((_) => operation());
    _writeQueue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> saveConfiguration(Map<String, dynamic> configuration) {
    return _serialized(() async {
      final prefs = await SharedPreferences.getInstance();
      final wrapper = {
        'schemaVersion': _currentSchemaVersion,
        'payload': configuration,
      };
      await prefs.setString(_configurationKey, jsonEncode(wrapper));
    });
  }

  Future<void> saveProgress(OnboardingProgress progress) {
    return _serialized(() async {
      final prefs = await SharedPreferences.getInstance();
      final wrapper = {
        'schemaVersion': _currentSchemaVersion,
        'payload': progress.toJson(),
      };
      await prefs.setString(_progressKey, jsonEncode(wrapper));
    });
  }
}
```

Bloc-side: delete the 2 SharedPreferences-mutex flags. **Keep**
`_isProcessingStep` / `_isCompletingOnboarding` (see correction below) —
they are not redundant with framework behavior.

- `_isSavingConfiguration` / static `_isSharedPrefsOperation` → removed,
  replaced by `_serialized()` in the service (real fix, same cross-method
  guarantee, no 10ms polling loop).
- `_isProcessingStep` / `_isCompletingOnboarding` → **retained, unchanged.**

  **Correction (verified against the pinned dependency, not assumed):**
  the earlier draft of this document claimed flutter_bloc processes
  same-type events sequentially by default. That claim was checked directly
  against source — `~/.pub-cache/hosted/pub.dev/bloc-9.2.1/lib/src/bloc.dart`
  (the `bloc` package flutter_bloc `^9.1.1` transitively resolves to per
  `pubspec.lock`) — and is **false**:

  ```dart
  static EventTransformer<dynamic> transformer = (events, mapper) {
    return events
        .map(mapper)
        .transform<dynamic>(const _FlatMapStreamTransformer<dynamic>());
  };
  ```

  `_FlatMapStreamTransformer` subscribes to each event's mapped handler
  stream as it arrives and lets them run concurrently — it does not wait
  for one handler to complete before starting the next. This is
  `concurrent()` semantics, not `sequential()`. Confirmed no override is in
  place: `grep -n "on<ProgressToStep>\|on<CompleteOnboarding>\|transformer"`
  on the bloc file shows both registered as bare `on<Event>(handler)` with
  no `transformer:` argument, so the (concurrent) default genuinely applies.

  Consequently, two rapid `ProgressToStep` (or `CompleteOnboarding`) events
  really can have overlapping handler executions today, and
  `_isProcessingStep`/`_isCompletingOnboarding` are the only thing
  preventing that — they are load-bearing, not dead code. They stay as-is.
  The rapid-double-dispatch test is still worth adding, but as a
  regression/documentation test for existing behavior, not as a gate for
  removing anything.

### Why this is proposed instead

- **Zero new dependencies.**
- **Fixes the actual bug class**, not a symptom: any future caller of
  `saveConfiguration`/`saveProgress` (from the service directly, from a
  test, from another bloc) gets the same write-safety, instead of safety
  that only exists if you go through this one bloc's event handlers.
- **SRP**: the class that talks to `SharedPreferences` is the class
  responsible for making that access safe.
- **Strictly less code and no busy-waiting** — `_serialized()` replaces a
  10ms-interval `while` spin-loop with a proper future chain; no CPU spent
  polling.
- **Testable in isolation** — write-ordering can be unit-tested directly
  against `OnboardingService` without spinning up a full `Bloc` +
  `bloc_test` harness.

### Residual risk / what to verify

- **Queue-error-recovery test (new gate, same rigor as above).** The claim
  that `onError: (_) {}` prevents a failed write from wedging `_writeQueue`
  is exactly as falsifiable as the transformer claim was, and gets the same
  treatment: a test where `saveConfiguration()` is made to throw (e.g. by
  injecting a failing write) followed immediately by `saveProgress()`,
  asserting the second call still completes and does not hang. This test
  must exist and pass before `_serialized()` is considered verified rather
  than "should be fine."
- **Read/write concurrency gap (explicit, not a regression).**
  `_serialized()` only serializes `saveConfiguration()` / `saveProgress()`
  (writes). `loadConfiguration()` / `loadProgress()` are not queued through
  it, so a load can still interleave with an in-flight write. This is **not
  a regression** — the original bloc's mutex flags
  (`_isSavingConfiguration`, static `_isSharedPrefsOperation`) only ever
  wrapped the two save methods; the two load methods were never guarded
  against concurrent writes in the current code either. Stated here
  explicitly so it isn't an implicit, undocumented gap in the new design.
- `_isProcessingStep` / `_isCompletingOnboarding` remain in the bloc
  unchanged, per the correction above — no further verification needed
  beyond the existing rapid-double-dispatch test confirming they still
  behave as before.

## Net effect vs. original plan

**Revised from the first draft of this document**, after the transformer
claim below was checked against source instead of asserted: 2 flags removed
from the bloc (the SharedPreferences mutex pair), not 4.
`_isProcessingStep` / `_isCompletingOnboarding` are retained because
flutter_bloc's default event transformer is concurrent, not sequential —
verified against `bloc-9.2.1/lib/src/bloc.dart`, the version this project's
`flutter_bloc: ^9.1.1` resolves to. One fewer dependency (no
`bloc_concurrency`), and the SharedPreferences write-safety guarantee is now
anchored to `OnboardingService`, the class that owns the resource it's
protecting, instead of the bloc that happened to call it first. Bloc line
count reduction from this piece alone is smaller than originally stated
(2 flags, not 4) — the larger reduction still comes from the dead-code
removal and method-relocation sections of the plan, which are unaffected by
this correction.

## Sign-off checklist (for architect review)

- [ ] Confirm 2-flag removal (not 4) is acceptable — `_isProcessingStep` /
      `_isCompletingOnboarding` stay in the bloc.
- [ ] Confirm `_serialized()` write queue design in `OnboardingService`.
- [ ] Require queue-error-recovery test before merge (saveConfiguration()
      throws → saveProgress() still completes, doesn't hang).
- [ ] Acknowledge read/write concurrency gap is pre-existing, not a
      regression — no action required, but noted.
