# TTS Service - Dependency Injection Migration Guide

## Overview

This guide documents the migration of the TTS (Text-to-Speech) service from a singleton pattern to dependency injection (DI), enabling code reuse across multiple applications with different state management frameworks (BLoC, Riverpod, Provider, etc.).

## What Changed

### Before: Singleton Pattern
```dart
// Direct instantiation always returned the same instance
final tts = TtsService(); // Singleton via factory constructor
```

### After: Dependency Injection
```dart
// Setup once at app startup
setupServiceLocator();

// Get instance through DI container
final tts = getService<ITtsService>();

// Or inject directly into consumers
final controller = AudioController(getService<ITtsService>());
```

## Architecture Changes

### 1. New Interface: `ITtsService`
**Location:** `lib/services/tts/i_tts_service.dart`

Defines the contract for TTS functionality, enabling:
- Decoupling from implementation
- Easy mocking for tests
- Framework-agnostic code

### 2. Service Locator: `ServiceLocator`
**Location:** `lib/services/service_locator.dart`

Lightweight DI container supporting:
- Lazy singletons (created on first access)
- Factory patterns (new instance each time)
- Explicit singletons

### 3. Updated TTS Service
**Location:** `lib/services/tts_service.dart`

Changes:
- Implements `ITtsService` interface
- Constructor now private (`TtsService._internal`)
- Factory constructor available for initialization
- Test constructor (`TtsService.forTest`) for injecting mocks

## Migration Steps for Consumers

### For New Code

#### AudioController
```dart
// ✅ Recommended: Constructor injection
class MyController {
  final ITtsService _ttsService;
  
  MyController(this._ttsService);
}

// Usage
setupServiceLocator(); // Once at app startup
final controller = MyController(getService<ITtsService>());
```

#### BLoC Pattern
```dart
class MyBloc extends Bloc<MyEvent, MyState> {
  final ITtsService _ttsService;
  
  MyBloc(this._ttsService) : super(InitialState());
}

// Usage
BlocProvider(
  create: (_) => MyBloc(getService<ITtsService>()),
  child: MyWidget(),
)
```

#### Provider Pattern
```dart
// In main.dart or app setup
MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) => AudioController(getService<ITtsService>()),
    ),
    // ... other providers
  ],
  child: MyApp(),
)
```

### For Existing Code

#### DevocionalProvider (Already Migrated)
```dart
class DevocionalProvider with ChangeNotifier {
  late final AudioController _audioController;
  
  DevocionalProvider() {
    // Uses service locator internally
    _audioController = AudioController(getService<ITtsService>());
    _audioController.initialize();
  }
}
```

#### Legacy Compatibility
The factory constructor still works for backward compatibility:
```dart
// ⚠️ Still works but not recommended
final tts = TtsService(); // Uses factory constructor
```

However, this creates a new instance each time and doesn't use the singleton from DI.

## App Initialization

**Required:** Call `setupServiceLocator()` once at app startup:

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  setupServiceLocator();
  
  runApp(MyApp());
}
```

## Testing

### Unit Tests with Mocks

```dart
test('My test with mocked TTS', () {
  // Create mock
  final mockTts = MockTtsService();
  
  // Inject into consumer
  final controller = AudioController(mockTts);
  
  // Test behavior
  // ...
});
```

### Integration Tests with Real Service

```dart
test('Integration test with real TTS', () {
  // Setup service locator
  ServiceLocator().reset();
  setupServiceLocator();
  
  // Get real service
  final tts = getService<ITtsService>();
  final controller = AudioController(tts);
  
  // Test integration
  // ...
  
  // Cleanup
  ServiceLocator().reset();
});
```

### Using Test Constructor

```dart
test('Test with custom dependencies', () {
  // Create test instance with mocked dependencies
  final mockFlutterTts = MockFlutterTts();
  final mockLocalization = MockLocalizationService();
  final mockVoiceSettings = MockVoiceSettingsService();
  
  final tts = TtsService.forTest(
    flutterTts: mockFlutterTts,
    localizationService: mockLocalization,
    voiceSettingsService: mockVoiceSettings,
  );
  
  // Test with mocked dependencies
  // ...
});
```

## Benefits

1. **Testability**: Easy to inject mocks for unit testing
2. **Flexibility**: Can swap implementations without changing consumers
3. **Portability**: Same code works with any state management framework
4. **Isolation**: Clear separation of concerns via interface
5. **Reusability**: Deploy once, use in multiple apps

## Common Issues

### Issue: "Service not registered" exception
**Solution**: Ensure `setupServiceLocator()` is called before accessing services

```dart
// ❌ Wrong
final tts = getService<ITtsService>(); // Error if setup not called

// ✅ Correct
setupServiceLocator(); // First
final tts = getService<ITtsService>(); // Then access
```

### Issue: Multiple instances instead of singleton
**Solution**: Use `getService<ITtsService>()` instead of `TtsService()`

```dart
// ❌ Wrong - creates new instance each time
final tts1 = TtsService();
final tts2 = TtsService();
assert(identical(tts1, tts2)); // false!

// ✅ Correct - returns singleton
final tts1 = getService<ITtsService>();
final tts2 = getService<ITtsService>();
assert(identical(tts1, tts2)); // true
```

### Issue: Tests fail with "Service not registered"
**Solution**: Reset and setup service locator in test setUp

```dart
setUp(() {
  ServiceLocator().reset();
  setupServiceLocator();
});

tearDown() {
  ServiceLocator().reset();
}
```

## Rollback Plan

If issues arise and rollback is needed:

1. Revert commits:
   ```bash
   git revert <commit-hash>
   ```

2. Restore singleton pattern in TtsService:
   ```dart
   class TtsService {
     static final TtsService _instance = TtsService._internal();
     factory TtsService() => _instance;
     TtsService._internal();
   }
   ```

3. Update consumers to use singleton directly:
   ```dart
   final controller = AudioController(); // Without injection
   ```

4. Run full test suite to verify

## Additional Resources

- [ITtsService Interface](../lib/services/tts/i_tts_service.dart)
- [ServiceLocator Implementation](../lib/services/service_locator.dart)
- [Integration Tests](../test/integration/tts_di_integration_test.dart)
- [Behavioral Tests](../test/unit/services/tts_service_behavior_test.dart)

## Questions or Issues?

For questions about the migration or issues encountered, please:
1. Check the integration tests for usage examples
2. Review the behavioral tests for expected behavior
3. Open an issue with detailed description and steps to reproduce
