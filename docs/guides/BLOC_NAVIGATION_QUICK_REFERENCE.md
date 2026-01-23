# Quick Reference: BLoC-Only Navigation

## Overview

The `DevocionalesPage` now uses **100% BLoC pattern** for state management and navigation.

---

## Key Components

### 1. Navigation BLoC

**File**: `lib/blocs/devocionales/devocionales_navigation_bloc.dart`

**States**:

- `NavigationInitial` - Before initialization
- `NavigationReady` - Ready to navigate (contains current devotional)
- `NavigationError` - Error state

**Events**:

- `InitializeNavigation` - Initialize with devotionals list
- `NavigateToNext` - Move to next devotional
- `NavigateToPrevious` - Move to previous devotional
- `NavigateToIndex` - Jump to specific index
- `NavigateToFirstUnread` - Jump to first unread
- `UpdateDevocionales` - Update list when language/version changes

### 2. Repository Layer

**File**: `lib/repositories/navigation_repository_impl.dart`

**Methods**:

- `saveCurrentIndex(int)` - Persist current position
- `loadCurrentIndex()` - Load saved position

**Storage**: SharedPreferences key `'lastDevocionalIndex'`

### 3. Page Implementation

**File**: `lib/pages/devocionales_page.dart`

**BLoC Instance**: `late DevocionalesNavigationBloc _navigationBloc`

---

## Navigation Flow

### Initialization

```dart
// 1. Create BLoC (synchronous)
_navigationBloc = DevocionalesNavigationBloc
(
navigationRepository: NavigationRepositoryImpl(),
devocionalRepository: DevocionalRepositoryImpl(),
);

// 2. Initialize asynchronously
_initializeNavigationBloc
(
);
```

### Navigation (Next/Previous)

```dart
void _goToNextDevocional() async {
  // 1. Check BLoC is ready (race condition guard)
  if (_navigationBloc.state is! NavigationReady) {
    return; // Blocked
  }

  // 2. Stop audio
  await _audioController?.stop();

  // 3. Dispatch event
  _navigationBloc.add(const NavigateToNext());

  // 4. UI updates
  _scrollToTop();
  HapticFeedback.mediumImpact();

  // 5. Analytics
  await getService<AnalyticsService>().logNavigationNext(...);
}
```

### State Updates

```dart
BlocBuilder<DevocionalesNavigationBloc, DevocionalesNavigationState>
(
builder: (context, state) {
if (state is NavigationReady) {
// Show devotional at state.currentIndex
return DevocionalesContentWidget(
devocional: state.currentDevocional,
);
} else {
// Show loading
return CircularProgressIndicator();
}
},
)
```

---

## Safety Features

### 1. Race Condition Prevention

**Location**: Navigation methods

```dart
// Guard added at start of _goToNextDevocional and _goToPreviousDevocional
if (_navigationBloc.state is! NavigationReady) {
debugPrint('⚠️ Navigation blocked: BLoC not ready yet');
return;
}
```

### 2. UI Loading State

**Location**: `_buildWithBloc` method

```dart
if (state is NavigationReady) {
// Show content
} else if (devocionalProvider.devocionales.isNotEmpty) {
// Show fallback
} else {
// Show loading spinner
return Scaffold(
body: Center(child: CircularProgressIndicator()),
);
}
```

### 3. Button State Management

**Location**: `DevocionalesBottomBar` widget

```dart
OutlinedButton.icon
(
onPressed
:
canNavigateNext
?
onNext
:
null
, // Auto-disabled
// ...
)
```

---

## Common Tasks

### How to: Add New Navigation Event

1. **Define Event** in `devocionales_navigation_event.dart`:

```dart
class NavigateToRandom extends DevocionalesNavigationEvent {
  const NavigateToRandom();
}
```

2. **Handle Event** in BLoC:

```dart
on<NavigateToRandom>(_onNavigateToRandom);

Future<void> _onNavigateToRandom(NavigateToRandom event,
    Emitter<DevocionalesNavigationState> emit,) async {
  if (state is! NavigationReady) return;
  final currentState = state as NavigationReady;

  final randomIndex = Random().nextInt(currentState.totalDevocionales);

  emit(NavigationReady.calculate(
    currentIndex: randomIndex,
    devocionales: currentState.devocionales,
  ));

  await _navigationRepository.saveCurrentIndex(randomIndex);
}
```

3. **Dispatch from UI**:

```dart
_navigationBloc.add
(
const
NavigateToRandom
(
)
);
```

### How to: Get Current State

```dart

final currentState = _navigationBloc.state;if (
currentState is NavigationReady) {
final currentIndex = currentState.currentIndex;
final currentDevocional = currentState.currentDevocional;
final canGoNext = currentState.canNavigateNext;
}
```

### How to: Listen to State Changes

```dart
BlocListener<DevocionalesNavigationBloc, DevocionalesNavigationState>
(
bloc: _navigationBloc,
listener: (context, state) {
if (state is NavigationReady) {
// Do something when navigation changes
_tracking.startDevocionalTracking(
state.currentDevocional.id,
_scrollController,
);
}
},
child
:
...
,
)
```

---

## Debugging

### Check BLoC State

```dart
debugPrint
('Current BLoC state: 
${_navigationBloc.state}');

if (_navigationBloc.state is NavigationReady) {
final state = _navigationBloc.state as NavigationReady;
debugPrint('Current index: ${state.currentIndex}');
debugPrint('Current devotional: ${state.currentDevocional.id}');
debugPrint('Can navigate next: ${state.canNavigateNext}');
debugPrint('Can navigate previous: ${state.canNavigatePrevious}');
}
```

### Check Persistence

```dart

final repo = NavigationRepositoryImpl();
final savedIndex = await
repo.loadCurrentIndex
();debugPrint
('Saved index: 
$savedIndex'
);
```

### Monitor Events

Add logging to BLoC constructor:

```dart
on<NavigateToNext>
(
(event, emit) async {
debugPrint('🔵 NavigateToNext event received');
await _onNavigateToNext(event, emit);
});
```

---

## Testing

### Unit Test BLoC

```dart
blocTest<DevocionalesNavigationBloc, DevocionalesNavigationState>
('navigates to next devotional
'
,build: () => DevocionalesNavigationBloc(
navigationRepository: mockNavigationRepository,
devocionalRepository: mockDevocionalRepository,
),
seed: () => NavigationReady.calculate(
currentIndex: 0,
devocionales: testDevocionales,
),
act: (bloc) => bloc.add(const NavigateToNext()),
expect: () => [
isA<NavigationReady>().having((s) => s.currentIndex, 'currentIndex', 1),
]
,
);
```

### Widget Test

```dart
testWidgets
('navigation buttons work
'
, (tester) async {
await tester.pumpWidget(MyApp());

// Find next button
final nextButton = find.byKey(const Key('bottom_nav_next_button'));

// Tap it
await tester.tap(nextButton);
await tester.pump();

// Verify navigation occurred
verify(() => mockNavigationBloc.add(const NavigateToNext())).called(1);
});
```

---

## Migration Notes

### From Legacy Code

If you find old code using:

- `_currentDevocionalIndex` → Use `_navigationBloc.state.currentIndex`
- `setState(() => _currentDevocionalIndex++)` → Use `_navigationBloc.add(NavigateToNext())`
- `getCurrentDevocional()` → Use `_navigationBloc.state.currentDevocional`
- `_saveCurrentDevocionalIndexLegacy()` → BLoC auto-persists

### Analytics Migration

Old parameter `viaBloc: 'false'` is removed. All events now use `viaBloc: 'true'`.

---

## Performance Tips

1. **Don't rebuild unnecessarily**: Use `BlocBuilder` only for parts that need to rebuild
2. **Use BlocListener**: For side effects (analytics, tracking)
3. **Avoid duplicate events**: Check current state before dispatching
4. **Batch updates**: If multiple changes needed, use single event

---

## Common Pitfalls

### ❌ Don't Do This

```dart
// Accessing state before BLoC is ready
final currentIndex = _navigationBloc.state.currentIndex; // Might crash!
```

### ✅ Do This Instead

```dart

final currentState = _navigationBloc.state;if (
currentState is NavigationReady) {
final currentIndex = currentState.currentIndex; // Safe
}
```

### ❌ Don't Do This

```dart
// Calling setState to change navigation
setState
(
() {
_currentDevocionalIndex++; // This variable doesn't exist anymore!
});
```

### ✅ Do This Instead

```dart
// Dispatch event to BLoC
_navigationBloc.add
(
const
NavigateToNext
(
)
);
```

---

## Resources

- **BLoC Pattern**: [bloclibrary.dev](https://bloclibrary.dev)
- **Tests**: `test/critical_coverage/devocionales_navigation_bloc_test.dart`
- **Examples**: `lib/pages/devocionales_page.dart`
- **Documentation**:
    - [LEGACY_CODE_REMOVAL_SUMMARY.md](./LEGACY_CODE_REMOVAL_SUMMARY.md)
    - [RISK_ASSESSMENT_AND_MITIGATION.md](./RISK_ASSESSMENT_AND_MITIGATION.md)

---

**Last Updated**: January 20, 2026  
**Status**: Production Ready ✅
