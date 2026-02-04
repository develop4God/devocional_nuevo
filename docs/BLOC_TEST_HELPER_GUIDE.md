# Quick Reference: Using the BLoC Test Helper

## Basic Usage

```dart
import '../../helpers/bloc_test_helper.dart';

void main() {
  late DiscoveryBlocTestBase testBase;
  late DiscoveryBloc bloc;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    testBase = DiscoveryBlocTestBase();
    testBase.setupMocks();
  });

  tearDown(() {
    bloc.close();
  });

  // Your tests here...
}
```

## Common Test Patterns

### 1. Test Empty State

```dart
blocTest<DiscoveryBloc, DiscoveryState>
('emits empty state when no studies
'
,build: () {
testBase.mockEmptyIndexFetch();
return DiscoveryBloc(
repository: testBase.mockRepository,
progressTracker: testBase.mockProgressTracker,
favoritesService: testBase.mockFavoritesService,
);
},
act: (bloc) => bloc.add(LoadDiscoveryStudies()),
expect: () => [
isA<DiscoveryLoading>(),
isA<DiscoveryLoaded>()
    .having((s) => s.availableStudyIds, 'availableStudyIds', isEmpty
)
,
]
,
);
```

### 2. Test With Data

```dart
blocTest<DiscoveryBloc, DiscoveryState>
('emits loaded state with studies
'
,build: () {
final studies = [
testBase.createSampleStudy(id: 'study-1', titleEs: 'Study 1'),
testBase.createSampleStudy(id: 'study-2', titleEs: 'Study 2'),
];
testBase.mockIndexFetchWithStudies(studies);
return DiscoveryBloc(
repository: testBase.mockRepository,
progressTracker: testBase.mockProgressTracker,
favoritesService: testBase.mockFavoritesService,
);
},
act: (bloc) => bloc.add(LoadDiscoveryStudies()),
expect: () => [
isA<DiscoveryLoading>(),
isA<DiscoveryLoaded>()
    .having((s) => s.availableStudyIds, 'ids', ['study-1', 'study-2']),
]
,
);
```

### 3. Test Error Handling

```dart
blocTest<DiscoveryBloc, DiscoveryState>
('emits error when fetch fails
'
,build: () {
testBase.mockIndexFetchFailure('Network error');
return DiscoveryBloc(
repository: testBase.mockRepository,
progressTracker: testBase.mockProgressTracker,
favoritesService: testBase.mockFavoritesService,
);
},
act: (bloc) => bloc.add(LoadDiscoveryStudies()),
expect: () => [
isA<DiscoveryLoading>(),
isA<DiscoveryError>()
    .having((s) => s.message, 'message', contains('Network error')),
],
);
```

### 4. Custom Study Data

```dart

final customStudy = testBase.createSampleStudy(
  id: 'custom-study',
  titleEs: 'Mi Estudio',
  titleEn: 'My Study',
  emoji: '✨',
  minutes: 10,
);
testBase.mockIndexFetchWithStudies
([customStudy
]
);
```

## Helper Methods Reference

### `setupMocks()`

Sets up all mock objects with default behaviors.

### `mockEmptyIndexFetch()`

Mocks a successful API call that returns no studies.

### `mockIndexFetchWithStudies(List<Map<String, dynamic>> studies)`

Mocks a successful API call with the provided study data.

### `mockIndexFetchFailure(String errorMessage)`

Mocks an API call that throws an exception.

### `createSampleStudy({...})`

Creates a properly formatted study map for testing.

**Parameters:**

- `id` (required): Unique study identifier
- `titleEs`: Spanish title (default: 'Test Study')
- `titleEn`: English title (default: 'Test Study EN')
- `emoji`: Study emoji (default: '📖')
- `minutes`: Estimated reading time (default: 5)

### `createMockDevocionalProvider({...})`

Creates a MockDevocionalProvider with default behaviors configured.

**Parameters:**

- `favoriteDevocionales`: List of favorite devotionals (default: empty list)
- `selectedLanguage`: Current language code (default: 'es')

**Returns:** Configured MockDevocionalProvider

**Example:**

```dart
// Default mock (empty favorites, Spanish)
final mockProvider = createMockDevocionalProvider();

// Custom mock with data
final mockProvider = createMockDevocionalProvider(
  favoriteDevocionales: [devocional1, devocional2],
  selectedLanguage: 'en',
);
```

## When to Use Widget Tests vs Unit Tests

### Use Unit Tests (Fast) For:

- ✅ State transitions
- ✅ Event handling
- ✅ Business logic
- ✅ Error states
- ✅ Data transformations

### Use Widget Tests (Slow) For:

- ✅ User interactions (taps, swipes, gestures)
- ✅ Widget-BLoC integration
- ✅ Navigation flows
- ✅ Critical user journeys
- ✅ Regression tests for specific bugs

## Running Tests

```bash
# Fast unit tests only (recommended during development)
flutter test test/unit/blocs/discovery_bloc_state_transitions_test.dart

# Exclude slow tests (all unit tests + fast widget tests)
flutter test --exclude-tags=slow

# Include slow tests (full suite)
flutter test

# Only slow integration tests
flutter test --tags=slow
```

## Tips

1. **Always use `blocTest`** from the `bloc_test` package - it handles async properly
2. **Use `pumpAndSettle()`** in widget tests instead of multiple `pump()` calls
3. **Mock early, test often** - Set up mocks in `setUp()` for consistency
4. **Test one thing** - Each test should verify a single behavior
5. **Name tests clearly** - Use descriptive names that explain the scenario

## Example Test File Structure

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_bloc.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_event.dart';
import 'package:devocional_nuevo/blocs/discovery/discovery_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/bloc_test_helper.dart';

void main() {
  group('Feature Name', () {
    late DiscoveryBlocTestBase testBase;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testBase = DiscoveryBlocTestBase();
      testBase.setupMocks();
    });

    group('Sub-feature 1', () {
      blocTest<DiscoveryBloc, DiscoveryState>('test 1', ...);
      blocTest<DiscoveryBloc, DiscoveryState>('test 2', ...);
    });

    group('Sub-feature 2', () {
      blocTest<DiscoveryBloc, DiscoveryState>('test 3', ...);
    });
  });
}
```
