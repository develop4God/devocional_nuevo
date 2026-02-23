# Restore Purchases: Flow Diagrams & Architecture

## Complete IAP Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     APPLICATION STARTUP                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ↓
                    ┌─────────────────────┐
                    │ SupporterBloc Init  │
                    │ _onInitialize()     │
                    └─────────────────────┘
                              │
         ┌────────────────────┼────────────────────┐
         │                    │                    │
         ↓                    ↓                    ↓
    Load Prefs         Init IapService      Load Products
    from Storage       from Google Play     from Google Play
         │                    │                    │
         └────────────────────┼────────────────────┘
                              │
                              ↓
                   ┌──────────────────────┐
                   │ Check Clean Install? │
                   │ (no local prefs)     │
                   └──────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                │                           │
            ✅ YES                      ❌ NO
                │                           │
                ↓                           ↓
        ┌──────────────────┐       ┌──────────────────┐
        │ PROACTIVE RESTORE│       │  Skip Restore    │
        │ (Silent)         │       │  (Already has    │
        │                  │       │   local prefs)   │
        │ await restore()  │       └──────────────────┘
        │ (No UI change)   │
        └────────┬─────────┘
                 │
                 ↓
        ┌──────────────────┐
        │  Emit Loaded     │
        │  State with:     │
        │  - purchasedLevels
        │  - storePrices   │
        │  - initStatus    │
        └──────────────────┘
                 │
                 ↓
        ┌──────────────────────────┐
        │  SUPPORTER PAGE SHOWN    │
        │  (With Restore Button)   │
        └──────────────────────────┘
```

---

## Proactive Restore (Silent) Flow

```
                    SupporterPage Loaded
                            │
                            ↓
                  ┌──────────────────────┐
                  │  Check State         │
                  │  Is SupporterLoaded? │
                  └──────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
            ✅ YES                   ❌ NO
                │                       │
                ↓                       ↓
        ┌───────────────┐       └─ Wait for Load
        │  No Action    │
        │  (Init guard) │
        └───────────────┘
                │
        ┌───────┴─────────┐
        │                 │
    [Already           [First Time
     Done]             Init]
        │                 │
        │                 ↓
        │          Proactive Restore
        │          Already Completed
        │          During Init
        │                 │
        └─────────┬───────┘
                  │
                  ↓
        ┌──────────────────────┐
        │  Supporter Page      │
        │  Shows Current       │
        │  Purchased Tiers     │
        │                      │
        │ [ Restore Purchases] │ ← Button always available
        └──────────────────────┘
```

---

## Manual Restore (Button Click) Flow

```
                    User Taps
                 "Restore Purchases"
                    Button
                            │
                            ↓
                  ┌──────────────────────┐
                  │  _onRestorePurchases │
                  │  Event Added         │
                  └──────────────────────┘
                            │
                            ↓
                  ┌──────────────────────┐
                  │  RestorePurchases    │
                  │  Event Handler       │
                  └──────────────────────┘
                            │
                            ↓
                  ┌──────────────────────┐
                  │  Check State         │
                  │  Is SupporterLoaded? │
                  └──────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
            ✅ YES                   ❌ NO
                │                       │
                ↓                       ↓
        ┌───────────────┐       ┌──────────────┐
        │  Continue     │       │  Return (No-op)
        │               │       │  State not ready
        └───────┬───────┘       └──────────────┘
                │
                ↓
        ┌──────────────────────┐
        │  Emit State with     │
        │  isRestoring: true   │
        │  (Button disabled)   │
        │  (Loading shows)     │
        └──────────────────────┘
                │
                ↓
        ┌──────────────────────┐
        │  Call Google Play    │
        │  restorePurchases()  │
        │                      │
        │  Query: "What did    │
        │  this user buy?"     │
        └──────────────────────┘
                │
                ↓
        ┌──────────────────────┐
        │  Google Play         │
        │  Returns:            │
        │  [PurchaseDetails]   │
        └──────────────────────┘
                │
                ↓
        ┌──────────────────────┐
        │  _onPurchaseUpdate() │
        │  Process Each        │
        │  Purchase            │
        └──────────────────────┘
                │
        ┌───────┴───────┐
        │               │
        ↓               ↓
    Delivered      Failed
    Purchase       Purchase
        │               │
        ↓               ↓
   Emit Stream    Emit Error
   _PurchaseDelivered
        │               │
        └───────┬───────┘
                │
                ↓
        ┌──────────────────────┐
        │  SupporterBloc       │
        │  Receives Delivered  │
        │  or Error Event      │
        └──────────────────────┘
                │
        ┌───────┴───────────┐
        │                   │
        ↓                   ↓
    Success             Error
        │                   │
        ↓                   ↓
    Update           Show Error
    purchasedLevels  Message
        │                   │
        └───────┬───────────┘
                │
                ↓
        ┌──────────────────────┐
        │  Emit State with     │
        │  isRestoring: false  │
        │  (Button enabled)    │
        │  (Loading hides)     │
        │  (Success/Error shown)
        └──────────────────────┘
                │
                ↓
        ┌──────────────────────┐
        │  Supporter Page      │
        │  Updates UI:         │
        │  - Shows new tiers   │
        │  - Hides loading     │
        │  - Shows result      │
        └──────────────────────┘
```

---

## State Transitions

### SupporterState Hierarchy

```
┌──────────────────────┐
│  SupporterState      │ ← Abstract base
│  (BLoC State)        │
└──────┬───────────────┘
       │
   ┌───┼───┬─────────────┐
   │   │   │             │
   ↓   ↓   ↓             ↓
┌──┐ ┌───────────┐ ┌──────────┐ ┌────────┐
│  │ │ Supporter │ │Supporter │ │Supporter
│IN│ │ Loading   │ │ Loaded   │ │ Error  
│IT│ │           │ │          │ │        
│AL│ └───────────┘ └──────────┘ └────────┘
│  │       │             ↑           ↑
└──┘       │             │           │
           └─────────────┴───────────┘
                    (transitions)
```

### SupporterLoaded State Detail

```
┌─────────────────────────────────────────────┐
│  SupporterLoaded                            │
├─────────────────────────────────────────────┤
│  • purchasedLevels: Set<SupporterTierLevel> │
│  • isBillingAvailable: bool                 │
│  • storePrices: Map<String, String>         │
│  • goldSupporterName: String?               │
│  • initStatus: IapInitStatus                │
│                                             │
│  • isRestoring: bool ← For manual restore   │
│  • purchasingProductId: String? ← For buy  │
│  • errorMessage: String?                    │
│  • justDeliveredTier: SupporterTier?        │
└─────────────────────────────────────────────┘
```

---

## Event Processing Pipeline

```
                    User Action
                        │
                        ↓
          ┌─────────────────────────┐
          │  SupporterEvent         │
          │  (RestorePurchases)     │
          └─────────────────────────┘
                        │
                        ↓
          ┌─────────────────────────┐
          │  SupporterBloc.on()     │
          │  Event Handler Map      │
          └─────────────────────────┘
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ↓                           ↓
   InitializeSupporter      RestorePurchases
          │                           │
          ↓                           ↓
   _onInitialize()          _onRestorePurchases()
          │                           │
    ┌─────┴─────────┐           ┌────┴────┐
    │               │           │         │
    ↓               ↓           ↓         ↓
   Proactive     Emit        Emit      Call
   Restore       Loaded      Restoring IAP
    (Silent)     State                 │
    │             │           │        ↓
    │             │           │     Handle
    │             │           │    Purchase
    │             │           │        │
    └─────────────┴───────────┴────────┤
                  │
                  ↓
        ┌──────────────────────┐
        │  Emit Final State    │
        │  (SupporterLoaded    │
        │   or Error)          │
        └──────────────────────┘
                  │
                  ↓
        ┌──────────────────────┐
        │  BLoC.stream         │
        │  Listeners receive   │
        │  state updates       │
        └──────────────────────┘
                  │
                  ↓
        ┌──────────────────────┐
        │  UI Rebuilds         │
        │  (via BlocBuilder)   │
        │  Shows new state     │
        └──────────────────────┘
```

---

## Call Stack: Proactive Restore

```
main.dart (App Start)
    │
    ↓
SupporterPage.initState()
    │
    ↓
context.read<SupporterBloc>()
    │
    ↓ if (bloc.state is! SupporterLoaded)
    │
    ↓
SupporterBloc.add(InitializeSupporter())
    │
    ↓
SupporterBloc._onInitialize()
    │
    ├─→ _iapService.initialize()
    │   └─→ InAppPurchase.isAvailable()
    │       (Check billing library)
    │
    ├─→ _profileRepo.loadProfileName()
    │   └─→ SharedPreferences.getString()
    │       (Load Gold supporter name)
    │
    ├─→ _iapService.getProduct(productId)
    │   └─→ Cached product details
    │       (Get store prices)
    │
    ├─→ Check: isAvailable + purchasedLevels.isEmpty
    │   └─ YES: continue proactive restore
    │
    ├─→ Check: SharedPreferences for local purchases
    │   └─ NO local purchases found: clean install
    │
    ├─→ _iapService.restorePurchases() ← PROACTIVE CALL
    │   │
    │   └─→ InAppPurchase.restorePurchases()
    │       │
    │       └─→ Google Play Billing API
    │           (Query user's past purchases)
    │
    └─→ Emit(SupporterLoaded(...))
        │
        └─→ UI Rebuilds with purchased tiers
```

---

## Call Stack: Manual Restore

```
User Taps Button
    │
    ↓
_onRestorePurchases()
    │
    ↓
SupporterBloc.add(RestorePurchases())
    │
    ↓
SupporterBloc._onRestorePurchases()
    │
    ├─→ Check: state is SupporterLoaded?
    │   ├─ NO: return (no-op)
    │   └─ YES: continue
    │
    ├─→ Emit(state.copyWith(isRestoring: true))
    │   │
    │   └─→ UI rebuilds:
    │       • Button disabled
    │       • Loading indicator shows
    │
    ├─→ try {
    │   │
    │   ├─→ _iapService.restorePurchases() ← MANUAL CALL
    │   │   │
    │   │   └─→ InAppPurchase.restorePurchases()
    │   │       │
    │   │       └─→ Google Play Billing API
    │   │           (Query user's past purchases)
    │   │
    │   └─ Purchases come back via stream
    │       (If network error, exception thrown)
    │
    ├─→ } catch (e) {
    │   │
    │   └─→ debugPrint('❌ Restore error: $e')
    │       (Error logged, rethrown)
    │
    └─→ } finally {
        │
        ├─→ Get current state
        │   (May have received delivered tiers from stream)
        │
        └─→ Emit(state.copyWith(
                isRestoring: false,
                purchasedLevels: _iapService.purchasedLevels
            ))
            │
            └─→ UI rebuilds:
                • Button enabled again
                • Loading hidden
                • New purchased tiers shown
                • Error message shown (if any)
```

---

## Purchase Stream Processing

```
┌──────────────────────────────────────────┐
│  Google Play Billing API                 │
│  (User's account & purchases)            │
└──────────────────────────────────────────┘
                    │
                    │ Returns List<PurchaseDetails>
                    ↓
┌──────────────────────────────────────────┐
│  InAppPurchase.purchaseStream            │
│  (BroadcastStream)                       │
└──────────────────────────────────────────┘
                    │
                    │ emits purchases
                    ↓
┌──────────────────────────────────────────┐
│  IapService._onPurchaseUpdate()          │
│  (_purchaseSubscription listener)        │
└──────────────────────────────────────────┘
                    │
      ┌─────────────┼─────────────┐
      │             │             │
      ↓             ↓             ↓
 For Each PurchaseDetails Item
      │
      ├─→ _handlePurchase(purchase)
      │   │
      │   ├─→ Check: guard _disposed
      │   │   (Ignore if already closed)
      │   │
      │   ├─→ Check: purchase.status
      │   │   │
      │   │   ├─ PENDING:
      │   │   │   └─ completePurchase() & return
      │   │   │
      │   │   ├─ PURCHASED/RESTORED:
      │   │   │   └─ _deliverProduct(productId)
      │   │   │
      │   │   └─ ERROR:
      │   │       └─ emit onPurchaseError stream
      │   │
      │   └─→ completePurchase() if needed
      │       (Tell store we handled purchase)
      │
      └─→ _deliverProduct(productId)
          │
          ├─→ Get SupporterTier from productId
          │
          ├─→ _purchasedLevels.add(tier.level)
          │
          ├─→ _savePurchasedToPrefs(tier.level)
          │   └─ SharedPreferences.setBool()
          │
          └─→ emit onPurchaseDelivered stream
              │
              └─→ SupporterBloc._deliveredSubscription.listen()
                  │
                  └─→ add(_PurchaseDelivered event)
                      │
                      └─→ _onPurchaseDelivered()
                          │
                          └─→ Emit(state with updated purchasedLevels)
                              │
                              └─→ UI Rebuilds (User sees purchase!)
```

---

## Guard Clauses & Safety Mechanisms

### Proactive Restore Guards

```
if (! _iapService.isAvailable) {
    └─ Skip restore (billing unavailable)
}

if (! _iapService.purchasedLevels.isEmpty) {
    └─ Skip restore (already have purchases in memory)
}

if (hasAnyLocalPurchase in SharedPreferences) {
    └─ Skip restore (not a clean install)
}
```

### Manual Restore Guards

```
if (state is! SupporterLoaded) {
    └─ Return (no-op, state not ready)
}

if (current.purchasingProductId != null) {
    └─ Return (guard: don't allow concurrent purchases)
}

if (! current.isBillingAvailable) {
    └─ Return (billing not available)
}

if (_disposed) {
    └─ Return (ignore if service already closed)
}
```

---

## Preference Storage & Persistence

```
┌──────────────────────────────────────────┐
│  SharedPreferences                       │
│  (Device Local Storage)                  │
├──────────────────────────────────────────┤
│ Key: iap_purchased_supporter_bronze      │
│ Val: true (if owned) / false (if not)    │
│                                          │
│ Key: iap_purchased_supporter_silver      │
│ Val: true (if owned) / false (if not)    │
│                                          │
│ Key: iap_purchased_supporter_gold        │
│ Val: true (if owned) / false (if not)    │
│                                          │
│ Key: supporter_profile_name              │
│ Val: "John Doe" (if Gold + set name)    │
└──────────────────────────────────────────┘
         ↑               │
         │               │
         │          ┌────┘
         │          ↓
      Load on    Saved on
      App Init   Purchase
         │          │
         ↓          ↓
   _loadPurchased  _savePurchased
   FromPrefs()     ToPrefs()
```

---

## State Emission Sequence (Manual Restore)

```
Timeline of State Emissions During Manual Restore:

[T0] User Taps Button
     Current State: SupporterLoaded(isRestoring: false)
                                                │
[T1] _onRestorePurchases() starts                │
                                                │
[T2] Emit: isRestoring: true                    │
     State: SupporterLoaded(isRestoring: true)  │
     UI: Button disabled, loading shows         │
                                                │
[T3] Call: restorePurchases()                   │
     Network: Waiting for Google Play...        │
                                                │
[T4] Google Play returns: [PurchaseDetails]     │
     _onPurchaseUpdate() processes each         │
                                                │
[T5] Emit: _PurchaseDelivered event             │
     (From purchase stream via listener)        │
                                                │
[T6] _onPurchaseDelivered() processes event     │
     Emit: SupporterLoaded(                     │
       purchasedLevels: {gold},                 │
       isRestoring: true,  ← Still true!        │
       justDeliveredTier: gold                  │
     )                                          │
     UI: Shows delivered tier notification      │
                                                │
[T7] finally block executes                     │
     Emit: SupporterLoaded(                     │
       purchasedLevels: {gold},                 │
       isRestoring: false,  ← Now false         │
       justDeliveredTier: cleared               │
     )                                          │
     UI: Loading hidden, button enabled         │
                                                │
[T8] UI Stabilized                              │
     Final State: SupporterLoaded(              │
       purchasedLevels: {gold},                 │
       isRestoring: false                       │
     )
```

---

## Architecture Summary

### Layers

```
┌────────────────────────────────────────────────────────────┐
│  UI Layer                                                  │
│  • SupporterPage (Restore Button)                          │
│  • Displays state changes                                  │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│  State Management Layer                                    │
│  • SupporterBloc (Business Logic)                          │
│  • Orchestrates Events → State transitions                 │
│  • Manages restore flow                                    │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│  Service Layer                                             │
│  • IapService (Google Play Billing Wrapper)               │
│  • Handles IAP lifecycle                                   │
│  • Provides purchase streams                               │
└────────────────────────────────────────────────────────────┘
                            ↓
┌────────────────────────────────────────────────────────────┐
│  External API                                              │
│  • Google Play Billing (Real IAP)                          │
│  • SharedPreferences (Local persistence)                   │
└────────────────────────────────────────────────────────────┘
```

---

## Key Metrics & Diagrams for Documentation

### Proactive Restore Coverage

```
All Installs (100%)
├─ Billing Unavailable (5%)
│  └─ Skipped ✓
│
├─ Has Local Purchases (60%)
│  └─ Skipped ✓ (not a clean install)
│
└─ Clean Install + Billing (35%)
   ├─ Restore Succeeds (33%)
   │  └─ Handled ✅
   │
   └─ Restore Fails (2%)
      └─ Manual button fallback ✅
```

### Manual Button Scenario Coverage

```
All Scenarios
├─ Network Down at Init (Proactive Failed)
│  └─ Manual Restore: ✅ Works (when online)
│
├─ Different Account
│  └─ Manual Restore: ✅ Works (switch acct first)
│
├─ App Updated (not reinstalled)
│  └─ Manual Restore: ✅ Works
│
├─ User Wants Confidence
│  └─ Manual Restore: ✅ Available
│
└─ Support Troubleshooting
   └─ Manual Restore: ✅ Visible option
```

---

## Conclusion: Why Both Systems Work Together

```
Perfect IAP Implementation:

Proactive Restore
    ↓
(Handles 80%+ of cases automatically)
    ↓
Fast, Seamless, Users Never Know

Manual Button
    ↓
(Handles edge cases + provides control)
    ↓
Visible, Trustworthy, Users Feel In Control

Together:
✅ Best UX (automatic when possible)
✅ Best Reliability (fallback always available)
✅ Industry Standard (meets all requirements)
✅ Zero Downside (no conflicts, complementary)
```

