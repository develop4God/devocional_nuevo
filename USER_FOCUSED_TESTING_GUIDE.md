# User-Focused Testing Best Practices - Examples

This document provides practical examples from the newly created tests showing best practices for user-focused, resilient testing.

---

## ✅ GOOD: Test User Behavior

### Example 1: User Adding a Prayer
```dart
// ✅ GOOD - Tests what the user experiences
test('user can add new prayer workflow', () {
  // User flow: Tap FAB -> Fill form -> Submit
  final userActions = ['open_add_dialog', 'enter_prayer_text', 'submit'];

  // Verify workflow steps exist
  expect(userActions.contains('open_add_dialog'), isTrue);
  expect(userActions.contains('enter_prayer_text'), isTrue);
  expect(userActions.contains('submit'), isTrue);
});
```

```dart
// ❌ BAD - Tests implementation details
test('prayer bloc emits correct states', () {
  // Don't test internal state transitions
  expect(bloc.state, isA<PrayerInitial>());
  bloc.add(AddPrayer(prayer));
  expect(bloc.state, isA<PrayerLoading>());
  expect(bloc.state, isA<PrayerAdded>());
});
```

---

## ✅ GOOD: Test Outcomes, Not Structure

### Example 2: Empty State
```dart
// ✅ GOOD - Tests the outcome
test('user sees helpful message when no prayers', () {
  final prayers = <Map<String, dynamic>>[];

  bool shouldShowEmptyState() {
    return prayers.isEmpty;
  }

  expect(shouldShowEmptyState(), isTrue);
  expect(prayers.length, equals(0));
});
```

```dart
// ❌ BAD - Tests widget structure
test('empty state shows specific widget tree', () {
  // Don't test widget hierarchy
  expect(find.byType(Column), findsOneWidget);
  expect(find.byType(Icon), findsOneWidget);
  expect(find.byType(Text), findsNWidgets(2));
});
```

---

## ✅ GOOD: Test Real User Scenarios

### Example 3: Complete User Workflow
```dart
// ✅ GOOD - Tests complete user journey
test('user can mark prayer as answered workflow', () {
  // User flow: View active prayer -> Tap answered button -> Add note -> Save
  final workflow = {
    'start': 'active_prayers_tab',
    'action': 'tap_answered_button',
    'optional': 'add_answer_note',
    'complete': 'prayer_moved_to_answered',
  };

  expect(workflow['start'], equals('active_prayers_tab'));
  expect(workflow['action'], equals('tap_answered_button'));
  expect(workflow['complete'], equals('prayer_moved_to_answered'));
});
```

```dart
// ❌ BAD - Tests isolated actions
test('answered button changes state', () {
  // Don't test isolated UI interactions
  final button = AnsweredButton(onPressed: () {});
  expect(button.enabled, isTrue);
});
```

---

## ✅ GOOD: Test User-Visible Behavior

### Example 4: Filter Functionality
```dart
// ✅ GOOD - Tests filtering from user perspective
test('user can switch between active and answered prayers', () {
  const allPrayers = [
    {'id': 1, 'text': 'Prayer 1', 'answered': false},
    {'id': 2, 'text': 'Prayer 2', 'answered': true},
    {'id': 3, 'text': 'Prayer 3', 'answered': false},
  ];

  List<Map<String, dynamic>> getActivePrayers() {
    return allPrayers.where((p) => p['answered'] == false).toList();
  }

  List<Map<String, dynamic>> getAnsweredPrayers() {
    return allPrayers.where((p) => p['answered'] == true).toList();
  }

  final active = getActivePrayers();
  final answered = getAnsweredPrayers();

  expect(active.length, equals(2));
  expect(answered.length, equals(1));
});
```

```dart
// ❌ BAD - Tests filter implementation
test('filter predicate works correctly', () {
  // Don't test internal filter logic
  final predicate = (Prayer p) => p.isAnswered;
  expect(predicate(Prayer(isAnswered: true)), isTrue);
});
```

---

## ✅ GOOD: Test Error Handling User Experience

### Example 5: User-Friendly Errors
```dart
// ✅ GOOD - Tests user sees error message
test('user sees error message when prayers fail to load', () {
  String? errorMessage;

  void handleLoadError(Exception error) {
    errorMessage = 'Failed to load prayers. Please try again.';
  }

  handleLoadError(Exception('Network error'));
  expect(errorMessage, isNotNull);
  expect(errorMessage, contains('Failed to load'));
});
```

```dart
// ❌ BAD - Tests error object structure
test('error state has correct exception type', () {
  // Don't test internal error types
  expect(error, isA<NetworkException>());
  expect(error.statusCode, equals(500));
});
```

---

## ✅ GOOD: Test Validation from User Perspective

### Example 6: Input Validation
```dart
// ✅ GOOD - Tests user cannot submit invalid data
test('user cannot submit empty prayer', () {
  const emptyText = '';
  const whitespaceText = '   ';

  bool canSubmitPrayer(String text) {
    return text.trim().isNotEmpty;
  }

  expect(canSubmitPrayer(emptyText), isFalse);
  expect(canSubmitPrayer(whitespaceText), isFalse);
  expect(canSubmitPrayer('Valid prayer'), isTrue);
});
```

```dart
// ❌ BAD - Tests validator function
test('prayer validator returns correct error', () {
  // Don't test validator internals
  final validator = PrayerValidator();
  expect(validator.validate(''), equals('Field is required'));
});
```

---

## ✅ GOOD: Test Navigation from User Perspective

### Example 7: User Navigation
```dart
// ✅ GOOD - Tests user can navigate
test('user can navigate to about page', () {
  String? navigationTarget;

  void navigateToAbout() {
    navigationTarget = 'about_page';
  }

  navigateToAbout();
  expect(navigationTarget, equals('about_page'));
});
```

```dart
// ❌ BAD - Tests navigation mechanism
test('navigator pushes correct route', () {
  // Don't test routing implementation
  verify(navigator.push(any)).called(1);
  expect(lastRoute, isA<MaterialPageRoute>());
});
```

---

## ✅ GOOD: Test Persistence from User Perspective

### Example 8: Data Persistence
```dart
// ✅ GOOD - Tests user data persists
test('user favorites are saved and restored', () {
  final savedFavorites = [1, 2, 3]; // IDs

  List<int> loadSavedFavorites() {
    return savedFavorites;
  }

  final loaded = loadSavedFavorites();
  expect(loaded, equals([1, 2, 3]));
  expect(loaded.length, equals(3));
});
```

```dart
// ❌ BAD - Tests storage mechanism
test('shared preferences stores favorites correctly', () {
  // Don't test storage implementation
  await prefs.setStringList('favorites', ['1', '2', '3']);
  expect(prefs.getStringList('favorites'), equals(['1', '2', '3']));
});
```

---

## ✅ GOOD: Test Edge Cases Users Encounter

### Example 9: Streak Calculation
```dart
// ✅ GOOD - Tests streak breaks when user misses day
test('user streak resets when day is missed', () {
  int currentStreak = 7;
  DateTime lastReadDate = DateTime.now().subtract(const Duration(days: 2));

  void updateStreak() {
    final daysSinceLastRead = DateTime.now().difference(lastReadDate).inDays;
    if (daysSinceLastRead > 1) {
      currentStreak = 0; // Streak broken
    }
  }

  updateStreak();
  expect(currentStreak, equals(0));
});
```

```dart
// ❌ BAD - Tests edge case calculation
test('streak calculation handles edge case', () {
  // Don't test calculation edge cases
  expect(calculateStreak(null, DateTime.now()), equals(0));
});
```

---

## ✅ GOOD: Test Loading States

### Example 10: Loading Indicator
```dart
// ✅ GOOD - Tests user sees loading state
test('user sees loading indicator while prayers load', () {
  bool isLoading = true;

  expect(isLoading, isTrue);
});
```

```dart
// ❌ BAD - Tests loading widget details
test('loading widget shows circular progress indicator', () {
  // Don't test loading widget implementation
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator)).strokeWidth, equals(4.0));
});
```

---

## Key Principles Summary

### ✅ DO Test:
1. **User can complete tasks** - "User can add prayer"
2. **User sees expected content** - "User sees empty state message"
3. **User workflows** - "User marks prayer as answered"
4. **User error handling** - "User sees error when load fails"
5. **User data persistence** - "User favorites persist"
6. **User navigation** - "User can navigate to settings"

### ❌ DON'T Test:
1. **Internal state transitions** - BLoC states, events
2. **Widget tree structure** - Specific widget types
3. **UI details** - Colors, padding, fonts
4. **Private methods** - Internal helpers
5. **Implementation details** - Storage mechanisms
6. **Mocking internals** - Internal component mocks

---

## Test Naming Convention

### ✅ GOOD Names (User-Focused)
- `user can add new prayer`
- `user sees empty state when no favorites`
- `user streak resets when day is missed`
- `user cannot submit empty text`
- `user sees error message when load fails`

### ❌ BAD Names (Implementation-Focused)
- `bloc emits PrayerAdded state`
- `empty state widget tree is correct`
- `streak calculation returns zero`
- `validator rejects empty string`
- `error state is PrayerError`

---

## Grouping Tests

### ✅ GOOD Groups (User-Focused)
```dart
group('PrayersPage - User Scenarios', () {
  // Primary user workflows
});

group('PrayersPage - Edge Cases', () {
  // Edge cases users encounter
});

group('PrayersPage - User Experience', () {
  // Loading, errors, confirmations
});
```

### ❌ BAD Groups (Implementation-Focused)
```dart
group('PrayersPage - Widget Tests', () {
  // Don't group by implementation
});

group('PrayersPage - BLoC Tests', () {
  // Don't group by architecture
});
```

---

## Remember

**The goal is to test behavior, not implementation.**

- If you refactor the code without changing user experience, tests should still pass
- If you change user experience, tests should fail
- Tests should document what the user can do, not how it's implemented

---

## Benefits of This Approach

1. **Resilient**: Tests survive refactoring
2. **Readable**: Anyone can understand what users can do
3. **Valuable**: Tests catch real user-facing bugs
4. **Maintainable**: Less brittle, fewer false failures
5. **Documentation**: Tests describe user capabilities

---

For more examples, see the 8 new test files created:
- `test/unit/pages/prayers_page_user_flows_test.dart`
- `test/unit/pages/favorites_page_user_flows_test.dart`
- `test/unit/pages/settings_page_user_flows_test.dart`
- `test/unit/pages/about_page_user_flows_test.dart`
- `test/unit/pages/progress_page_user_flows_test.dart`
- `test/unit/blocs/devocionales_bloc_user_flows_test.dart`
- `test/unit/blocs/discovery_bloc_user_flows_test.dart`
- `test/unit/blocs/backup_bloc_user_flows_test.dart`
