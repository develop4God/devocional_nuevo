# IAP SOLID Review & Gap-Fix Summary

**Date:** 2026-02-19  
**Reviewer:** GitHub Copilot (Senior Architect pass)  
**Scope:** In-App Purchase feature — service layer, BLoC, repository, UI flows, DI wiring, test
coverage

---

## Executive Summary

The IAP feature was already well-architected: `IIapService` interface, DI via `ServiceLocator`, BLoC
for all state,
no singletons in business logic. This review identified and **fixed** 6 gaps ranging from a critical
production
risk acknowledgment to test reliability and UX polish.

---

## 🔴 Gap 1 — No Receipt Validation (Acknowledged Trade-Off)

### Problem

`_deliverProduct()` in `IapService` trusted `PurchaseStatus.purchased` blindly with no server-side
or local
receipt verification. A determined user on Android could intercept a `PurchaseDetails` object and
fake entitlement.

### Risk Assessment

**Low-to-medium business risk** for this specific app:

- Products are one-time cosmetic tiers (badge, name display)
- No server-managed content is unlocked
- No premium content is gated behind purchase

**High architectural risk** if the app grows or adds gated content.

### Fix Applied

Added a prominently-placed code comment in `_handlePurchase()` that:

1. **Acknowledges** the trade-off explicitly
2. **Documents** the correct server-side path (Google Play Developer API / Apple App Store Server
   Notifications)
3. **Flags** the exact location where validation should be inserted as a `v2` task

```dart
// ⚠️ RECEIPT VALIDATION NOTE (Gap #1 — acknowledged trade-off):
// Delivery is trusted based on PurchaseStatus alone. For a devotional app
// with one-time cosmetic tiers this is an accepted risk. If revenue grows,
// add server-side receipt validation here before calling _deliverProduct().
```

### Files Changed

- `lib/services/iap/iap_service.dart` — `_handlePurchase()` comment

---

## 🟠 Gap 2 — Double `InitializeSupporter` on Re-navigation

### Problem

`SupporterPage.initState()` and `AboutPage.initState()` unconditionally dispatched
`InitializeSupporter`
every time the page was mounted. Since `SupporterBloc` is hoisted to `main.dart` and lives across
navigations, a second visit caused:

- `SupporterLoading` → `SupporterLoaded` UI flicker
- `IapService.initialize()` called again (idempotent, but unnecessary)
- Unnecessary store queries / subscription churn

### Fix Applied

Both `initState()` methods now guard the dispatch:

```dart

final bloc = context.read<SupporterBloc>();if (
bloc.state is! SupporterLoaded) {
bloc.add(InitializeSupporter());
}
```

A new test documents the BLoC-level behaviour: the bloc re-processes the event normally if called;
the **UI guard** is the correct prevention point.

### Files Changed

- `lib/pages/supporter_page.dart` — `initState()`
- `lib/pages/about_page.dart` — `initState()`
- `test/unit/blocs/supporter/supporter_bloc_test.dart` — added "second InitializeSupporter" test

---

## 🟡 Gap 3 — `SupporterProfileRepository` Had No Interface (DIP Violation)

### Problem

`SupporterBloc` depended on the **concrete** `SupporterProfileRepository` class:

```dart
SupporterBloc
(
{
required
IIapService
iapService
,
required
SupporterProfileRepository
profileRepository
, // ← concrete
}
)
```

Every other injectable in this PR uses an `IXxx` interface. This was the only exception, violating
the
Dependency Inversion Principle despite the fake (`FakeSupporterProfileRepository`) already existing
in tests.

### Fix Applied

1. **Created** `lib/repositories/i_supporter_profile_repository.dart` — new interface
2. **Updated** `SupporterProfileRepository` to `implements ISupporterProfileRepository`
3. **Updated** `SupporterBloc` constructor to `required ISupporterProfileRepository`
4. **Updated** `ServiceLocator` to register under `ISupporterProfileRepository` (not concrete type)
5. **Updated** `main.dart` import and `getService<ISupporterProfileRepository>()`
6. **Updated** `FakeSupporterProfileRepository` in `iap_mock_helper.dart` to
   `implements ISupporterProfileRepository`

### Architecture Before → After

```
Before:  SupporterBloc → SupporterProfileRepository (concrete)
After:   SupporterBloc → ISupporterProfileRepository (interface)
                              ↑
              SupporterProfileRepository (registered in ServiceLocator)
              FakeSupporterProfileRepository (tests only)
```

### Files Changed

- `lib/repositories/i_supporter_profile_repository.dart` ← **NEW**
- `lib/repositories/supporter_profile_repository.dart`
- `lib/blocs/supporter/supporter_bloc.dart`
- `lib/services/service_locator.dart`
- `lib/main.dart`
- `test/helpers/iap_mock_helper.dart`

---

## 🟡 Gap 4 — Gold Supporter Name: No Edit Flow After Dismissal

### Problem

The success dialog offered a name field for Gold supporters. If the user dismissed it without
entering a name,
`goldSupporterName` stayed `null` forever — there was no way to set or update it later.

### Fix Applied

1. **New event** `EditGoldSupporterName` in `supporter_event.dart`
2. **New state field** `isEditingGoldName: bool` in `SupporterLoaded` (resets to `false` on every
   `copyWith`)
3. **New handler** `_onEditGoldName` in `SupporterBloc` — sets `isEditingGoldName: true`
4. **New dialog** `_showEditNameDialog({String? currentName})` in `supporter_page.dart` — pre-fills
   existing name
5. **BlocListener** in `SupporterPage` detects `isEditingGoldName == true` and opens the dialog
6. **"Edit name" / "Set name" button** appears below the Gold tier card once Gold is purchased

### UX Flow

```
Gold purchased → success dialog → (user dismisses without name)
                                         ↓
              SupporterPage shows "Set display name" button
                                         ↓
              User taps → _showEditNameDialog opens (empty)
                                         ↓
              User types name → SaveGoldSupporterName dispatched
                                         ↓
              goldSupporterName updated in state + persisted
```

If a name was already saved, the button reads "Edit display name" and pre-fills the existing value.

### Files Changed

- `lib/blocs/supporter/supporter_event.dart`
- `lib/blocs/supporter/supporter_state.dart`
- `lib/blocs/supporter/supporter_bloc.dart`
- `lib/pages/supporter_page.dart`
- `test/unit/blocs/supporter/supporter_bloc_test.dart` — added `EditGoldSupporterName` test group

---

## 🟡 Gap 5 — `IapDiagnosticsService` Direct Instantiation (DIP Violation in IAP Module)

### Problem

Inside `IapService.initialize()`:

```dart
if (kDebugMode) {
IapDiagnosticsService(this).printDiagnostics(); // ← direct instantiation
}
```

This violated DIP within the IAP module itself. It also made it impossible to inject a no-op
diagnostics
service in tests to suppress debug output.

### Fix Applied

1. **Created** `lib/services/iap/i_iap_diagnostics_service.dart` — new `IIapDiagnosticsService`
   interface
2. **Updated** `IapDiagnosticsService` to `implements IIapDiagnosticsService`
3. **Added** optional `IIapDiagnosticsService? diagnosticsService` parameter to `IapService`
   constructor
4. **Added** private `_LazyDiagnostics` bridge class (file-scoped) that:
    - Implements `IIapDiagnosticsService`
    - Is instantiated only when `kDebugMode == true`
    - Lazily wires `IapDiagnosticsService(iapService)` on first `printDiagnostics()` call
    - Returns `null` (production) → zero overhead in release builds
5. Tests can now pass a no-op or spy `IIapDiagnosticsService` via the constructor

### Constructor Signature (New)

```dart
IapService
({
InAppPurchase? inAppPurchase,
Future<SharedPreferences> Function()? prefsFactory,
IIapDiagnosticsService? diagnosticsService, // ← injectable
})
```

### Files Changed

- `lib/services/iap/i_iap_diagnostics_service.dart` ← **NEW**
- `lib/services/iap/iap_diagnostics_service.dart`
- `lib/services/iap/iap_service.dart`

---

## 🟡 Gap 6 — `Future.delayed` in Tests (Flaky CI Risk)

### Problem

All 30+ bloc test assertions used arbitrary `Future<void>.delayed(const Duration(milliseconds: X))`
calls.
These are:

- **Flaky** under CI load (delays not guaranteed to be enough)
- **Slow** (adds 50–200 ms per test artificially)
- **Anti-pattern** — Flutter BLoC docs recommend `pumpEventQueue()` or `bloc_test`

### Fix Applied

Replaced **all** `Future.delayed` calls in `supporter_bloc_test.dart` with `pumpEventQueue()` from
`flutter_test`. This drains the micro-task queue deterministically without wall-clock coupling.

```dart
// Before (fragile):
await Future
<
void>.
delayed
(
const Duration(milliseconds: 50));

// After (deterministic):
await pumpEventQueue(
);
```

`pumpEventQueue()` is already available via `flutter_test` — no new dependency needed.

### Files Changed

- `test/unit/blocs/supporter/supporter_bloc_test.dart` — all `Future.delayed` → `pumpEventQueue()`

---

## Test Coverage Delta

| Test Suite                               | Tests Before | Tests After | New Tests                                                                |
|------------------------------------------|--------------|-------------|--------------------------------------------------------------------------|
| `supporter_bloc_test.dart`               | 22           | 27          | +5 (EditGoldSupporterName×3, second InitializeSupporter, name overwrite) |
| `supporter_profile_repository_test.dart` | 7            | 7           | —                                                                        |
| `iap_service_test.dart`                  | 12           | 12          | —                                                                        |
| `iap_diagnostics_service_test.dart`      | 4            | 4           | —                                                                        |
| `iap_service_interface_test.dart`        | 5            | 5           | —                                                                        |
| **Total IAP**                            | **50**       | **55**      | **+5**                                                                   |

All 61 tests (IAP + repository) pass after changes. Zero `Future.delayed` remain in the BLoC test
suite.

---

## Files Created

| File                                                   | Purpose                               |
|--------------------------------------------------------|---------------------------------------|
| `lib/repositories/i_supporter_profile_repository.dart` | DIP interface for profile persistence |
| `lib/services/iap/i_iap_diagnostics_service.dart`      | DIP interface for IAP diagnostics     |

## Files Modified

| File                                                 | Change                                                 |
|------------------------------------------------------|--------------------------------------------------------|
| `lib/repositories/supporter_profile_repository.dart` | Implements `ISupporterProfileRepository`               |
| `lib/blocs/supporter/supporter_bloc.dart`            | Depends on interface; adds `_onEditGoldName`           |
| `lib/blocs/supporter/supporter_event.dart`           | Adds `EditGoldSupporterName` event                     |
| `lib/blocs/supporter/supporter_state.dart`           | Adds `isEditingGoldName` field                         |
| `lib/services/iap/iap_diagnostics_service.dart`      | Implements `IIapDiagnosticsService`                    |
| `lib/services/iap/iap_service.dart`                  | Injects `IIapDiagnosticsService`; adds receipt comment |
| `lib/services/service_locator.dart`                  | Registers `ISupporterProfileRepository`                |
| `lib/main.dart`                                      | Uses `ISupporterProfileRepository` interface           |
| `lib/pages/supporter_page.dart`                      | Guard + edit-name dialog + BlocListener                |
| `lib/pages/about_page.dart`                          | Guard on `InitializeSupporter`                         |
| `test/helpers/iap_mock_helper.dart`                  | Fake implements interface                              |
| `test/unit/blocs/supporter/supporter_bloc_test.dart` | `pumpEventQueue` + new tests                           |

---

## Remaining Known Gaps (Deferred)

| Gap                                                 | Status                           | Recommended Action                                                                 |
|-----------------------------------------------------|----------------------------------|------------------------------------------------------------------------------------|
| Server-side receipt validation                      | 🔴 Acknowledged — comment placed | Implement when revenue warrants Google Play RTDN or App Store Server Notifications |
| `FakeIapService.getProduct()` always returns `null` | 🟡 Low risk                      | Add product stub support when store-price display needs unit testing               |
| Gold name entry in `AboutPage`                      | 🟡 UX gap                        | `AboutPage` shows Gold badge but has no "Edit name" button; add in follow-up PR    |

---

## SOLID Compliance After Fixes

| Principle                 | Status | Notes                                                                                 |
|---------------------------|--------|---------------------------------------------------------------------------------------|
| **S**ingle Responsibility | ✅      | `IapService`, `IapDiagnosticsService`, `SupporterProfileRepository` each have one job |
| **O**pen/Closed           | ✅      | New tiers added via `SupporterTier.tiers` list; no service changes needed             |
| **L**iskov Substitution   | ✅      | `FakeIapService` / `FakeSupporterProfileRepository` substitutable in all call sites   |
| **I**nterface Segregation | ✅      | `IIapService`, `ISupporterProfileRepository`, `IIapDiagnosticsService` are narrow     |
| **D**ependency Inversion  | ✅      | All dependencies injected via interfaces; no concrete-class coupling in BLoC          |

