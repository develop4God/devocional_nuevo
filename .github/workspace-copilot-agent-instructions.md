# Workspace Copilot Agent Instructions

This file provides custom instructions for Copilot and AI coding agents working in this repository.
Please follow these guidelines to ensure code quality, maintainability, and consistency.

## General Guidelines

- **Always validate and confirm reading this file at the start of each Copilot agent session.**
- **Do not use or reference BuildContext across async gaps unless you use `if (context.mounted)` (
  Flutter >= 3.7) or capture the required objects (e.g., Navigator, MediaQuery) before the async
  gap.**
- **If you see the
  warning `Don't use 'BuildContext's across async gaps, guarded by an unrelated 'mounted' check`,
  fix it by using `context.mounted` or by capturing the required objects before the async gap.**
- **If you are unsure, prefer capturing the Navigator or other dependencies before any `await`
  statement.**
- **Do not run tests or commit code if there are known static analysis or compile errors. Always fix
  errors first.**
- **Keep code clean, formatted, and well-documented.**
- **Follow the BLoC pattern for state management.**
- **Use only `string_extensions.dart` for translation imports.**
- **After every code change, ALWAYS run 'get error' to check for errors before proceeding. Never
  forget this step.**

## How to Fix BuildContext Async Gap Warnings

1. **If using Flutter >= 3.7:**
    - After an `await`, check `if (!context.mounted) return;` before using `context`.
2. **If using older Flutter:**
    - Capture the required object (e.g., `final navigator = Navigator.of(context);`) before the
      `await`.
    - Use the captured object after the async gap instead of `context`.

## Example

```dart
// Good (Flutter >= 3.7)
await someAsync();if (!context.mounted) return;
Navigator.of(context).push(...);

// Good (any Flutter)
final navigator = Navigator.of(context);
await someAsync();
navigator
.
push
(
...
);
```

## When in Doubt

- If you see this warning again, follow the above steps and refer to this file for guidance.
- If you are not sure, ask for clarification or review the Flutter documentation for your version.
