# Test Helpers - Quick Reference Guide

## Overview

This directory contains reusable test utilities and mock objects for unit and widget tests.

---

## Available Helpers

### 1. `registerTestServices()`

**Use when:** Running tests that don't need analytics or Firebase services

```dart
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerTestServices();
  });
}
```

---

### 2. `registerTestServicesWithFakes()` ⭐ NEW

**Use when:** Running widget tests that use `AnalyticsService`

```dart
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    // This registers FakeAnalyticsService automatically
    registerTestServicesWithFakes();
  });

  testWidgets('my test', (tester) async {
    // Your analytics-using widget will work without Firebase
    await tester.pumpWidget(MyWidget());
  });
}
```

**What it does:**

- Sets up all services via `setupServiceLocator()`
- Replaces `AnalyticsService` with `FakeAnalyticsService`
- No Firebase initialization needed
- All analytics methods are no-ops (don't actually log)

---

### 3. `FakeAnalyticsService`

**Use when:** You need direct access to a fake analytics instance

```dart
import '../../helpers/test_helpers.dart';

void main() {
  late FakeAnalyticsService fakeAnalytics;

  setUp(() {
    fakeAnalytics = FakeAnalyticsService();
    serviceLocator.registerSingleton<AnalyticsService>(fakeAnalytics);
  });
}
```

**Available methods** (all are no-ops for testing):

- `logBottomBarAction({required String action})`
- `logTtsPlay()`
- `logDevocionalComplete({...})`
- `logNavigationNext({...})`
- `logNavigationPrevious({...})`
- `logFabTapped({required String source})`
- `logFabChoiceSelected({...})`
- `logDiscoveryAction({...})`
- `logCustomEvent({...})`
- `setUserProperty({...})`
- `setUserId(String? userId)`
- `resetAnalyticsData()`
- `logAppInit({...})`

---

### 4. `MockPathProviderPlatform`

**Use when:** Testing code that accesses file system paths

```dart
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });
}
```

---

## Common Testing Patterns

### Pattern 1: Widget Test with Analytics

```dart
@Tags(['unit', 'widgets'])
library;

import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    registerTestServicesWithFakes(); // ⭐ Use this!
  });

  testWidgets('widget uses analytics', (tester) async {
    await tester.pumpWidget(MyWidget());
    // Analytics calls won't crash or require Firebase
  });
}
```

### Pattern 2: BLoC Test

```dart
import '../../helpers/bloc_test_helper.dart';

void main() {
  late MockDiscoveryRepository mockRepo;

  setUp(() {
    mockRepo = MockDiscoveryRepository();
    // Setup mock behaviors
  });
}
```

### Pattern 3: Service Test

```dart
import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    registerTestServices();
    // Or registerTestServicesWithFakes() if analytics is involved
  });
}
```

---

## Avoiding Common Pitfalls

### ❌ DON'T: Call Firebase in Unit Tests

```dart
// BAD - This will fail
void main() {
  setUpAll(() async {
    await Firebase.initializeApp(); // ❌ Don't do this in unit tests
  });
}
```

### ✅ DO: Use Fake Services

```dart
// GOOD - Use the helper
void main() {
  setUpAll(() {
    registerTestServicesWithFakes(); // ✅ Provides fake analytics
  });
}
```

---

### ❌ DON'T: Use `pumpAndSettle()` with Lottie

```dart
// BAD - Will timeout
testWidgets
('test with Lottie
'
, (tester) async {
await tester.pumpWidget(widgetWithLottie());
await tester.pumpAndSettle(); // ❌ Lottie animations never settle
});
```

### ✅ DO: Use `pump()` for Single Frame

```dart
// GOOD - Single frame is enough
testWidgets
('test with Lottie
'
, (tester) async {
await tester.pumpWidget(widgetWithLottie());
await tester.pump(); // ✅ One frame is sufficient
});
```

---

## File Organization

```
test/
├── helpers/
│   ├── test_helpers.dart          ← General utilities (registerTestServices, FakeAnalyticsService)
│   ├── bloc_test_helper.dart      ← BLoC-specific mocks
│   ├── flutter_tts_mock.dart      ← TTS mocks
│   └── tts_controller_test_helpers.dart
├── unit/
│   ├── widgets/
│   ├── services/
│   └── blocs/
└── integration_test/
```

---

## When to Create New Helpers

**Create a new helper when:**

1. ✅ You're duplicating mock code across 3+ test files
2. ✅ The mock is complex (>20 lines)
3. ✅ Multiple teams will use it
4. ✅ It provides core testing infrastructure

**Don't create a helper when:**

1. ❌ It's only used in one test file
2. ❌ It's a simple 5-line mock
3. ❌ It's test-specific logic

---

## Contributing

When adding new helpers:

1. **Document it** - Add to this README
2. **Export it** - Add to helpers' export list
3. **Test it** - Ensure it works in isolation
4. **Name clearly** - Use descriptive names (FakeX, MockX, registerXServices)

---

## Need Help?

- Check existing tests for examples
- Review `test/helpers/*.dart` files
- See implementation docs in `docs/`

---

**Last Updated:** February 14, 2026  
**Maintained by:** Development Team

