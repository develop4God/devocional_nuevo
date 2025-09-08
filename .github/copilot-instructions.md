# devocional_nuevo - Custom Instructions

This is a Flutter repository focused on Christian devotional applications and tools. Please follow these guidelines when contributing:

## Project Overview
A cross-platform mobile application for daily Christian devotionals, featuring:
- Daily devotional content in multiple languages (Spanish, English, Portuguese, French)
- Backup and sync functionality with Google Drive
- Audio narration with Text-to-Speech
- User favorites and prayer management
- Spiritual statistics and progress tracking

## Repository Structure
- `lib/`: Main application code
- `lib/blocs/`: State management using BLoC pattern, grouped by feature
  - `lib/blocs/backup/`: Backup and sync BLoCs
  - `lib/blocs/devotional/`: Devotional content BLoCs  
  - `lib/blocs/auth/`: Authentication BLoCs
- `lib/screens/` or `lib/pages/`: UI screens and pages
- `lib/widgets/`: Reusable UI components
- `lib/services/`: Business logic and API services
- `lib/models/`: Data models and entities
- `lib/providers/`: Legacy Provider pattern (migrating to BLoC)
- `i18n/`: Internationalization files (es.json, en.json, pt.json, fr.json)
- `test/`: Unit, widget, and integration tests
- `assets/`: Images, audio files, and static resources

## Code Standards

### Required Before Each Commit
- Run `flutter pub get` to ensure dependencies are installed
- Run `flutter run` to validate compilation and app launch
- Run `flutter test` to ensure all tests pass
- Run `dart format .` to enforce consistent code style
- Run `dart analyze --fatal-infos` to resolve all warnings and errors

### Development Flow
1. Install dependencies: `flutter pub get`
2. Validate compilation: `flutter run`
3. Run tests: `flutter test --coverage`
4. Format code: `dart format .`
5. Analyze code: `dart analyze --fatal-infos`
6. Build validation: `flutter build apk --debug` (Android)

## Architecture Guidelines

### State Management
1. **Prefer BLoC pattern** for all new features and state management
2. Create dedicated subfolders in `lib/blocs/` for each feature group
3. Use **sealed classes** for BLoC states and events (Dart 3.0+)
4. Implement **Equatable** for all BLoC states and events
5. Keep business logic completely separate from UI components
6. Make UI widgets stateless when using BLoC

### File Naming Conventions
- BLoC files: `feature_bloc.dart`, `feature_event.dart`, `feature_state.dart`
- Screen files: `feature_page.dart` or `feature_screen.dart`
- Widget files: `feature_widget.dart`
- Service files: `feature_service.dart`
- Model files: `feature_model.dart`

### BLoC Implementation Guidelines
```dart
// States - use sealed classes
sealed class FeatureState extends Equatable {}
final class FeatureInitial extends FeatureState {}
final class FeatureLoading extends FeatureState {}

// Events - use sealed classes  
sealed class FeatureEvent extends Equatable {}
final class FeatureStarted extends FeatureEvent {}
```

## Key Technologies
- **Flutter SDK**: Latest stable version
- **State Management**: BLoC pattern (`flutter_bloc`, `equatable`)
- **Internationalization**: Custom i18n system with JSON files
- **Storage**: SharedPreferences for local data, Google Drive for backups
- **Audio**: `flutter_tts` for text-to-speech functionality
- **Authentication**: Google Sign-In for Drive integration

## Development Guidelines
1. **Do not modify** production code unless strictly necessary for the requested feature
2. **Maintain existing** project structure and organization patterns
3. **Write unit tests** for new functionality, especially BLoCs
4. **Document public APIs** and complex business logic
5. **Update i18n files** when adding new user-facing text (all 4 languages)
6. **Handle errors gracefully** with user-friendly messages
7. **Follow Material Design** principles for UI consistency
8. **Always use theme and or app bar contants

## Testing Requirements
- Write unit tests for all new BLoCs
- Write widget tests for custom widgets
- Ensure all existing tests continue to pass
- Use `bloc_test` package for testing BLoCs
- Mock external dependencies properly

## Code Quality
- Use meaningful variable and function names
- Add comments for complex business logic
- Keep functions small and focused
- Follow Dart/Flutter best practices
- Ensure null safety compliance
