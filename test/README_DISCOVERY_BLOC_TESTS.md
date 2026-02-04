# Discovery BLoC Test Suite

This directory contains optimized tests for the Discovery BLoC functionality.

## Quick Start

```bash
# Run fast unit tests (recommended during development)
flutter test test/unit/blocs/discovery_bloc_state_transitions_test.dart

# Run the critical integration test
flutter test test/widget/favorites_page_discovery_tab_test.dart

# Exclude all slow tests
flutter test --exclude-tags=slow
```

## Test Structure

### Unit Tests (Fast - ~100ms)

**Location:** `test/unit/blocs/discovery_bloc_state_transitions_test.dart`

Tests BLoC state transitions without widget overhead:

- ✅ LoadDiscoveryStudies event handling
- ✅ Empty state scenarios
- ✅ Loaded state with data
- ✅ Error state handling
- ✅ Initial state verification
- ✅ State transitions (Initial → Loading → Loaded)
- ✅ Error recovery on retry
- ✅ ClearDiscoveryError functionality

**Use these for:** Business logic, state transitions, error handling

### Widget Tests (Slow - ~2-3s)

**Location:** `test/widget/favorites_page_discovery_tab_test.dart`

Tests full widget-BLoC integration:

- ✅ Tab switching triggers lazy-load of Discovery studies
- ✅ No infinite spinner bug (regression protection)

**Tagged:** `@Tags(['slow', 'widget', 'integration'])`

**Use these for:** User interactions, critical user journeys, integration flows

## Helper Classes

**Location:** `test/helpers/bloc_test_helper.dart`

Reusable test infrastructure:

```dart

final testBase = DiscoveryBlocTestBase();
testBase.setupMocks
();testBase.mockEmptyIndexFetch
();
// Use testBase.mockRepository, mockProgressTracker, mockFavoritesService
```

See [`docs/BLOC_TEST_HELPER_GUIDE.md`](../../docs/BLOC_TEST_HELPER_GUIDE.md) for detailed usage.

## Documentation

- **[Test Optimization Summary](../../docs/TEST_OPTIMIZATION_SUMMARY.md)** - Overview of the
  optimization
- **[BLoC Test Helper Guide](../../docs/BLOC_TEST_HELPER_GUIDE.md)** - How to use the test helper
- **[Discovery BLoC Test Optimization](../../docs/DISCOVERY_BLOC_TEST_OPTIMIZATION.md)** - Detailed
  technical documentation

## Performance

| Test Suite   | Tests | Execution Time | Use Case           |
|--------------|-------|----------------|--------------------|
| Unit tests   | 7     | ~100ms         | Active development |
| Widget tests | 1     | ~2-3s          | Pre-commit, CI     |
| **Total**    | **8** | **~2-3s**      | Full coverage      |

**Previous:** 4 widget tests, ~10-15s total
**Improvement:** ~5x faster with better coverage

## Test Execution Strategies

### Development Workflow

```bash
# 1. Make changes to BLoC
# 2. Run fast tests for immediate feedback
flutter test test/unit/blocs/discovery_bloc_state_transitions_test.dart

# 3. If all pass, run full suite before commit
flutter test --exclude-tags=slow  # Still fast
flutter test                      # Include slow tests
```

### CI/CD Pipeline

```bash
# Stage 1: Fast tests (parallel)
flutter test --exclude-tags=slow

# Stage 2: Slow integration tests (after fast tests pass)
flutter test --tags=slow
```

## Adding New Tests

### For State Transitions (Use Unit Tests)

```dart
import '../../helpers/bloc_test_helper.dart';

blocTest<DiscoveryBloc, DiscoveryState>
('your test description
'
,build: () {
testBase.mockEmptyIndexFetch();
return DiscoveryBloc(
repository: testBase.mockRepository,
progressTracker: testBase.mockProgressTracker,
favoritesService: testBase.mockFavoritesService,
);
},
act: (bloc) => bloc.add(YourEvent()),
expect: () =>
[
ExpectedState
(
)
]
,
);
```

### For User Interactions (Use Widget Tests)

```dart
testWidgets
('your test description
'
, (tester) async {
// Set up mocks
testBase.mockEmptyIndexFetch();

// Build widget tree
await tester.pumpWidget(/* your widget */);

// Interact
await tester.tap(find.byIcon(Icons.something));
await tester.pumpAndSettle();

// Assert
expect(find.text('Result'), findsOneWidget);
});
```

## Best Practices

1. ✅ **Prefer unit tests** for state transitions and business logic
2. ✅ **Use widget tests** only for critical user flows
3. ✅ **Tag slow tests** with `@Tags(['slow'])`
4. ✅ **Reuse `DiscoveryBlocTestBase`** for consistent mocking
5. ✅ **Use `pumpAndSettle()`** instead of multiple `pump()` calls
6. ✅ **Test one behavior** per test case
7. ✅ **Name tests descriptively** - explain what and why

## Troubleshooting

### Tests are slow

- Make sure you're running unit tests, not widget tests
- Use `--exclude-tags=slow` to skip integration tests
- Check if you're building full widget trees unnecessarily

### Mocks not working

- Verify `setupMocks()` is called in `setUp()`
- Check mock method is configured for your scenario
- Use `verify()` to confirm mock was called

### State transitions not as expected

- Add `.listen()` to bloc.stream to debug state changes
- Use `blocTest` instead of manual expectation checks
- Ensure async operations complete before assertions

## Questions?

Refer to the documentation in `docs/`:

- `BLOC_TEST_HELPER_GUIDE.md` - Detailed examples
- `DISCOVERY_BLOC_TEST_OPTIMIZATION.md` - Technical details
- `TEST_OPTIMIZATION_SUMMARY.md` - Overview

Or search existing tests for examples of similar scenarios.
