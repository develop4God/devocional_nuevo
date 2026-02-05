# User-Focused Testing - Quick Reference Card

## The Golden Rule
**Test what users see and do, not how the code works internally.**

---

## ✅ Test This (User-Facing Behavior)

| Category | Example |
|----------|---------|
| **User Actions** | "User can add prayer" |
| **User Sees Content** | "User sees empty state message" |
| **User Navigation** | "User can navigate to settings" |
| **User Workflows** | "User marks prayer as answered" |
| **User Errors** | "User sees error when load fails" |
| **User Data** | "User favorites persist across sessions" |
| **User Validation** | "User cannot submit empty text" |
| **User States** | "User sees loading indicator" |

---

## ❌ Don't Test This (Implementation Details)

| Category | Example |
|----------|---------|
| **Internal States** | "BLoC emits PrayerAdded state" |
| **Widget Tree** | "Page has Column with 3 children" |
| **UI Details** | "Button has blue color" |
| **Private Methods** | "_validateInput returns true" |
| **Storage Mechanism** | "SharedPreferences stores key" |
| **Event Handling** | "onPressed callback is called" |
| **Animation Details** | "Animation duration is 300ms" |
| **Mock Internals** | "Mock repository was called" |

---

## Test Pattern Template

```dart
@Tags(['unit', 'pages']) // or 'blocs', 'services', etc.
library;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComponentName - User Scenarios', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    // SCENARIO: Clear user scenario description
    test('user can perform specific action', () {
      // Arrange: Set up user's starting state
      final userState = setupInitialState();

      // Act: User performs action
      performUserAction();

      // Assert: User sees expected outcome
      expect(userState.result, isExpectedOutcome);
    });
  });

  group('ComponentName - Edge Cases', () {
    // Edge cases users encounter
  });

  group('ComponentName - User Experience', () {
    // Loading states, errors, confirmations
  });
}
```

---

## Test Naming Convention

### ✅ Good (User-Focused)
- `user can add prayer`
- `user sees error when offline`
- `user favorites persist`
- `user cannot submit empty form`

### ❌ Bad (Implementation-Focused)
- `add prayer emits correct state`
- `offline error returns NetworkException`
- `favorites stored in SharedPreferences`
- `form validation returns error`

---

## Common Patterns

### 1. User Can Do Action
```dart
test('user can add new item', () {
  final items = <String>[];
  items.add('New item');
  expect(items.length, equals(1));
});
```

### 2. User Sees Content
```dart
test('user sees welcome message', () {
  const message = 'Welcome to the app';
  expect(message, isNotEmpty);
  expect(message, contains('Welcome'));
});
```

### 3. User Handles Empty State
```dart
test('user sees message when no items', () {
  final items = <String>[];
  expect(items.isEmpty, isTrue);
});
```

### 4. User Filters/Searches
```dart
test('user can filter items', () {
  final filtered = items.where((i) => i.contains('search')).toList();
  expect(filtered.length, greaterThan(0));
});
```

### 5. User Sees Error
```dart
test('user sees error message', () {
  String? error;
  void handleError() => error = 'Failed to load';
  handleError();
  expect(error, contains('Failed'));
});
```

### 6. User Data Persists
```dart
test('user settings persist', () {
  final saved = {'theme': 'dark'};
  final loaded = loadSettings();
  expect(loaded['theme'], equals('dark'));
});
```

---

## What Makes a Good User-Focused Test?

### ✅ Characteristics
1. **Readable** - Anyone can understand what user does
2. **Resilient** - Survives refactoring
3. **Realistic** - Tests real user scenarios
4. **Valuable** - Catches real bugs
5. **Simple** - One scenario per test
6. **Clear** - Obvious what's being tested

### ❌ Red Flags
1. Testing private methods
2. Verifying mock calls
3. Checking widget types
4. Testing colors/padding
5. Multiple scenarios in one test
6. Implementation-focused names

---

## Before Writing a Test, Ask:

1. **Is this what a user experiences?**
   - ✅ Yes → Good test candidate
   - ❌ No → Reconsider

2. **Will this break if I refactor?**
   - ✅ No → Resilient test
   - ❌ Yes → Too implementation-focused

3. **Does this test real user value?**
   - ✅ Yes → High-value test
   - ❌ No → Low-value test

4. **Is this a real user scenario?**
   - ✅ Yes → Realistic test
   - ❌ No → Theoretical test

---

## Quick Decision Tree

```
Is it something the user sees or does?
├── YES → Good test ✅
│   ├── Can user complete a task?
│   ├── Does user see expected content?
│   ├── Can user navigate correctly?
│   └── Does user get appropriate feedback?
│
└── NO → Reconsider ❌
    ├── Is it internal state?
    ├── Is it widget structure?
    ├── Is it implementation detail?
    └── Is it private method?
```

---

## Test Coverage Priorities

### 1. Critical User Paths (Highest Priority)
- User can sign up/login
- User can complete main workflows
- User can save/load data
- User sees critical content

### 2. Common User Scenarios
- User navigates between pages
- User filters/searches content
- User favorites items
- User sees statistics

### 3. Edge Cases Users Encounter
- Empty states
- Error handling
- Invalid inputs
- Offline scenarios

### 4. Nice to Have
- UI polish
- Animations
- Advanced features

---

## Tagging Convention

```dart
@Tags(['unit', 'pages'])        // Page tests
@Tags(['unit', 'blocs'])        // BLoC tests
@Tags(['unit', 'services'])     // Service tests
@Tags(['unit', 'models'])       // Model tests
@Tags(['integration'])          // Integration tests
@Tags(['slow'])                 // Tests > 1 minute
```

---

## Running Tests

```bash
# All new user flow tests
flutter test test/unit/pages/*_user_flows_test.dart test/unit/blocs/*_user_flows_test.dart

# By category
flutter test --tags=pages
flutter test --tags=blocs

# Fast tests only
flutter test --exclude-tags=slow
```

---

## Remember

> "If a test fails when you refactor without changing user experience, 
> it's testing implementation, not behavior."

> "If a test passes when you break user experience, 
> it's not testing the right thing."

---

## Examples Repository

See these files for complete examples:
- `test/unit/pages/prayers_page_user_flows_test.dart`
- `test/unit/pages/favorites_page_user_flows_test.dart`
- `test/unit/pages/progress_page_user_flows_test.dart`
- `test/unit/blocs/devocionales_bloc_user_flows_test.dart`
- `test/unit/blocs/discovery_bloc_user_flows_test.dart`

---

## Additional Resources

- `HIGH_VALUE_TESTS_SUMMARY.md` - Complete summary of new tests
- `USER_FOCUSED_TESTING_GUIDE.md` - Detailed examples and patterns

---

**Keep this card handy when writing tests! 📋**
