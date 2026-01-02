# Patrol Integration Tests

This directory contains integration tests migrated to use the [Patrol](https://patrol.leancode.co/) framework.

## Migration Status

✅ **Completed Migrations:**
1. `devotional_reading_workflow_test.dart` - Service-level devotional reading tests
2. `tts_audio_test.dart` - TTS audio controller integration tests  
3. `offline_mode_test.dart` - Offline mode drawer UI tests with native interactions

## What is Patrol?

Patrol is a powerful testing framework for Flutter that extends `flutter_test` with:
- Native automation capabilities (permissions, notifications, etc.)
- Simplified syntax with `$` shorthand
- Better support for complex UI interactions
- Cross-platform native features

## Key Changes from integration_test

### 1. Import Changes
```dart
// Before
import 'package:flutter_test/flutter_test.dart';

// After
import 'package:patrol/patrol.dart';
```

### 2. Test Function Signatures
```dart
// Before
testWidgets('description', (WidgetTester tester) async { ... });
test('description', () async { ... });

// After  
patrolWidgetTest('description', (PatrolTester $) async { ... });
patrolTest('description', ($) async { ... });
```

### 3. Finder Shortcuts
```dart
// Before
find.byKey(Key('my_key'))
find.text('My Text')
find.byIcon(Icons.download)

// After (Patrol shorthand)
$(#my_key)
$('My Text')
$(Icons.download)
```

### 4. Pump Methods
```dart
// Before
await tester.pumpWidget(widget);
await tester.pumpAndSettle();

// After
await $.pumpWidgetAndSettle(widget);
```

### 5. Native Interactions (New Feature)
```dart
// Audio permissions
await $.native.grantPermissionWhenInUse();

// Notification permissions
await $.native.openNotifications();

// Back button
await $.native.pressBack();

// Share sheet
await $.native.shareSheet;
```

## Running Tests

```bash
# Run all Patrol tests
flutter test patrol_test/

# Run specific test
flutter test patrol_test/offline_mode_test.dart

# Run with patrol CLI (for native features)
patrol test
```

## Test Organization

- **Service Tests**: Use `patrolTest()` for non-UI logic tests
- **Widget Tests**: Use `patrolWidgetTest()` for UI interaction tests
- **Native Features**: Use `$.native.*` methods for platform-specific interactions

## Original Test Locations

| Patrol Test | Original Location |
|-------------|------------------|
| `devotional_reading_workflow_test.dart` | `integration_test/devotional_reading_workflow_test.dart` |
| `tts_audio_test.dart` | `integration_test/tts_complete_user_flow_test.dart` |
| `offline_mode_test.dart` | `integration_test/drawer_offline_integration_test.dart` |

## Native Features Added

### offline_mode_test.dart
- ✅ `$.native.pressBack()` - Close drawer using system back button
- 🔜 Could add: Permission requests for storage/downloads

### tts_audio_test.dart
- 🔜 Could add: `$.native.grantPermissionWhenInUse()` for audio permissions
- 🔜 Could add: Background audio testing

### devotional_reading_workflow_test.dart
- 🔜 Could add: Notification interaction tests
- 🔜 Could add: Share sheet testing

## Test Coverage

All migrated tests maintain identical:
- ✅ Test assertions
- ✅ Test logic and flow
- ✅ Mock setups
- ✅ Edge case coverage

## Benefits of Patrol Migration

1. **Better Syntax**: Cleaner, more readable test code
2. **Native Support**: Can test platform-specific features
3. **Future-Proof**: Modern testing framework with active development
4. **Cross-Platform**: Same tests work on Android and iOS with native features
5. **Debugging**: Better error messages and stack traces

## Next Steps

1. ✅ Migrate priority tests (completed)
2. 📋 Run migrated tests to verify functionality
3. 📋 Add native interactions where applicable
4. 📋 Document any platform-specific behaviors
5. 📋 Consider migrating remaining integration tests

## Resources

- [Patrol Documentation](https://patrol.leancode.co/)
- [Patrol GitHub](https://github.com/leancodepl/patrol)
- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
