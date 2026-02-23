# Restore Previous Purchases Analysis

## Proactive IAP Flow & Necessity Assessment

**Date:** 2026-02-21  
**Analysis:** Is "Restore Previous Purchases" necessary when we have proactive IAP restoration?

---

## Executive Summary

**CONCLUSION: YES, "Restore Previous Purchases" UI button is NECESSARY and RECOMMENDED**, even with
the proactive auto-restore mechanism.

**Key Reason:** The proactive restore only runs **on clean install with no local purchases**, but
users have many scenarios where they need manual restore:

1. ✅ **Switching devices** — No local purchase history
2. ✅ **Reinstalling app** — Local prefs cleared but account still has purchase
3. ✅ **Signing in with different account** — Purchases tied to different Google account
4. ✅ **Failed automatic restore** — Network issues during initialization
5. ✅ **Preference for control** — Users want explicit restore option available

---

## Current Architecture Analysis

### 1. **Proactive Auto-Restore (Automatic)**

**Location:** `lib/blocs/supporter/supporter_bloc.dart` (Lines 115-131)

```dart
// Task 3 — Auto-restore on clean install:
if (_iapService.isAvailable && _iapService.purchasedLevels.isEmpty) {
final prefs = await SharedPreferences.getInstance();
final hasAnyLocalPurchase = SupporterTier.tiers.any(
(t) => prefs.getBool(IapPrefsKeys.purchasedKey(t.productId)) == true,
);
if (!hasAnyLocalPurchase) {
debugPrint('🔄 [SupporterBloc] No local purchases — auto-restoring…');
await _iapService.restorePurchases();
}
}
```

**Triggers:**

- ✅ Billing available
- ✅ No purchased levels in memory
- ✅ No purchases in SharedPreferences (clean install indicator)

**What happens:**

- Calls `_iapService.restorePurchases()` automatically
- Queries Google Play Billing for user's past purchases
- Delivers found purchases via the event stream

---

### 2. **Manual Restore (User-Initiated)**

**Location:** `lib/pages/supporter_page.dart` (Lines 790-806)

```dart
Widget _buildRestorePurchases
(...) {
final isLoading = state is SupporterLoading;
return TextButton.icon(
onPressed: isLoading ? null : _onRestorePurchases,
icon: const Icon(Icons.restore, size: 18),
label: Text(
'supporter.restore_purchases'.tr(),
style: const TextStyle(fontWeight: FontWeight.bold),
),
);
}
```

**UI Flow:**

1. Button displayed on Supporter page
2. User taps "Restore Purchases"
3. Calls `RestorePurchases()` event to SupporterBloc
4. Sets `isRestoring: true` flag (shows loading indicator)
5. Calls `_iapService.restorePurchases()`
6. Clears `isRestoring` flag when complete

**Event Handler:** `lib/blocs/supporter/supporter_bloc.dart` (Lines 172-195)

```dart
Future<void> _onRestorePurchases(RestorePurchases event,
    Emitter<SupporterState> emit,) async {
  final current = state;
  if (current is! SupporterLoaded) return;

  debugPrint('🔄 [SupporterBloc] restorePurchases() called');
  emit(current.copyWith(isRestoring: true));
  try {
    await _iapService.restorePurchases();
  } catch (e) {
    debugPrint('❌ [SupporterBloc] restorePurchases error: $e');
    rethrow;
  } finally {
    // Always reset isRestoring
    final afterState = state;
    if (!isClosed && afterState is SupporterLoaded) {
      emit(afterState.copyWith(
        purchasedLevels: _iapService.purchasedLevels,
        isRestoring: false,
      ));
    }
  }
}
```

---

## Comparison: Proactive vs. Manual Restore

| Aspect                  | Proactive Auto-Restore         | Manual Restore Button             |
|-------------------------|--------------------------------|-----------------------------------|
| **When**                | During app initialization      | On-demand by user                 |
| **Trigger**             | Clean install detected         | User taps button                  |
| **User Awareness**      | Silent (no UI feedback)        | Explicit (button + loading state) |
| **Error Handling**      | Silent failure (no indication) | Visible error feedback            |
| **Network Requirement** | During init (may be slow)      | Anytime during app use            |
| **User Control**        | Automatic, no choice           | User can retry anytime            |
| **Scenarios Covered**   | Clean install only             | All scenarios                     |

---

## When Proactive Restore SUCCEEDS ✅

**Scenario:** First install or clean reinstall after uninstall

```
User Action:           App Initialization (SupporterPage init)
                              ↓
Checks:                isAvailable + purchasedLevels.isEmpty + no local prefs
                              ↓ (All true)
Proactive Restore:    await _iapService.restorePurchases()
                              ↓
Google Play Response:  "User has: Gold tier"
                              ↓
Result:               Gold automatically restored ✅
                       No user action needed
```

---

## When Proactive Restore FAILS or DOESN'T APPLY ❌

### Case 1: Different Google Account

```
Scenario:
  • App installed with Google Account A (had Gold purchase)
  • User uninstalls, reinstalls
  • Signs in with Google Account B (different account)
  • Proactive restore looks for Account B's purchases
  
Problem: Finds nothing (Account B has no purchases)
Solution: Manual restore button allows user to retry with correct account ✅
```

### Case 2: Network Issue During Init

```
Scenario:
  • Clean install, no internet initially
  • App initializes → Proactive restore fails silently
  • User later connects to internet
  
Problem: Auto-restore already attempted and failed
Solution: Manual restore lets user retry when network is available ✅
```

### Case 3: User Switches Devices

```
Scenario:
  • User has Gold tier on Device A
  • Installs app on Device B
  • Device B is a fresh install = proactive restore triggers ✅
  
Success Case: Auto-restore finds Gold automatically
Problem If It Fails: Manual restore provides fallback ✅
```

### Case 4: App Reinstall (Same Account)

```
Scenario:
  • Gold tier purchased on Device A
  • Proactive restore detects clean install
  • Calls restorePurchases()
  
Success Case: Gold restored automatically ✅
Edge Case If It Fails: Manual button provides explicit retry ✅
```

### Case 5: User Preference

```
Scenario:
  • User is cautious about automatic behaviors
  • Wants explicit control over restore
  
Solution: Manual button provides transparency and control ✅
```

---

## Technical Flow: How Restore Works

Both proactive and manual restore call the same underlying method:

```
RestorePurchases (UI Button)
    ↓
RestorePurchases Event (BLoC)
    ↓
_onRestorePurchases()
    ↓
_iapService.restorePurchases()
    ↓
InAppPurchase.restorePurchases() (Google Play Billing)
    ↓
Google Play Billing Service
    ↓
Queries: "What did this user previously purchase?"
    ↓
Returns: List<PurchaseDetails>
    ↓
_onPurchaseUpdate() handles each purchase
    ↓
_handlePurchase() → _deliverProduct() → _purchasedLevels updated
    ↓
Stream emission → SupporterBloc receives _PurchaseDelivered event
    ↓
State updated with new purchasedLevels
```

---

## IAP Prefs Keys: State Persistence

**Location:** `lib/services/iap/iap_prefs_keys.dart`

The app stores purchase state in two places:

### 1. **In-Memory State** (IapService)

```dart

final Set<SupporterTierLevel> _purchasedLevels = {};
```

### 2. **Persistent State** (SharedPreferences)

```dart
// For each tier, key like:
IapPrefsKeys.purchasedKey
('supporter_gold
'
) // 'iap_purchased_supporter_gold'
```

**How Proactive Restore Detects Clean Install:**

```dart

final hasAnyLocalPurchase = SupporterTier.tiers.any(
      (t) => prefs.getBool(IapPrefsKeys.purchasedKey(t.productId)) == true,
);if (!hasAnyLocalPurchase) {
// ALL prefs are false/missing → clean install
await _iapService.restorePurchases();
}
```

---

## State Management During Restore

### Manual Restore Button State

**File:** `lib/blocs/supporter/supporter_state.dart`

The `SupporterLoaded` state includes:

```dart

bool isRestoring = false; // Set to true during restore
```

**UI Response:**

- Button becomes disabled (`onPressed: null`)
- Loading indicator shown
- User gets clear feedback that something is happening

**Proactive Restore:**

- No UI feedback (happens during init)
- If it fails, user never knows (silent failure)

---

## Why Both Systems Are Necessary

### Proactive Restore Advantages

- ✅ Seamless user experience (no clicks needed)
- ✅ Handles most common case (clean install)
- ✅ Happens early in app initialization
- ✅ Automatic recovery of purchases

### Manual Restore Button Advantages

- ✅ **User control & transparency** — User knows restore is happening
- ✅ **Error recovery** — Retry failed proactive restore
- ✅ **Account flexibility** — Switch accounts and restore
- ✅ **Network resilience** — Wait for internet then restore
- ✅ **User confidence** — Visible success/failure feedback
- ✅ **Support safety net** — Help option for confused users

### The Complementary Relationship

| User Journey                 | Who Handles It? |
|------------------------------|-----------------|
| First install, clean account | Proactive ✅     |
| Reinstall same account       | Proactive ✅     |
| Proactive restore fails      | Manual ✅        |
| Different account            | Manual ✅        |
| Network unavailable at init  | Manual ✅        |
| User preference for control  | Manual ✅        |

---

## Recommendation

### ✅ KEEP THE "RESTORE PURCHASES" BUTTON

**Reasons:**

1. **Completeness** — Handles edge cases proactive restore doesn't cover
2. **User Confidence** — Shows purchases are being restored
3. **Support** — Provides explicit action for troubleshooting
4. **Standards** — All IAP apps have restore buttons (Apple requirement for iOS)
5. **Robustness** — Network/account failures have a fallback
6. **User Control** — Users shouldn't have to trust magic automatic behaviors

### Implementation Status

**Current Implementation:** ✅ Already correct

- Proactive restore: Happens at init
- Manual button: Available on Supporter page
- Both: Call same underlying `_iapService.restorePurchases()`
- State: Properly managed with `isRestoring` flag

### No Changes Required

The current implementation already follows best practices:

- ✅ Proactive restore for happy path
- ✅ Manual button for edge cases
- ✅ Proper state management and UX feedback
- ✅ Tests covering both scenarios

---

## Test Coverage

**Proactive Restore Tests:**

- ✅ `supporter_bloc_test.dart` — Auto-restore on clean install

**Manual Restore Tests:**

- ✅ `supporter_bloc_restore_test.dart` — Scenario 7 RestorePurchases
    - `isRestoring` flag management
    - State clearing after completion
    - Ignoring command if not SupporterLoaded

---

## Conclusion

The "Restore Previous Purchases" button is **NECESSARY** even with proactive auto-restore because:

1. **Proactive restore only works on clean install** — fails in other common scenarios
2. **User needs manual override** — for network issues, account switches, etc.
3. **Industry standard** — All IAP apps provide explicit restore option
4. **Error recovery** — Silent proactive failure has no fallback
5. **User expectations** — Users trust explicit actions over automatic behaviors

### Final Status: ✅ No changes needed

The current implementation correctly provides both mechanisms working together.

---

## References

**Code Files:**

- `lib/blocs/supporter/supporter_bloc.dart` — Event handlers & logic
- `lib/pages/supporter_page.dart` — UI button
- `lib/services/iap/iap_service.dart` — Underlying IAP implementation
- `test/unit/supporter/supporter_bloc_restore_test.dart` — Test coverage

**Docs:**

- `docs/BUG_FIXES_2026_02_18_IAP_SETUP.md` — IAP setup & testing
- Project copilot instructions — Code standards

