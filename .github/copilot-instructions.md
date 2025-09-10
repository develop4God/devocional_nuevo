- **copilot allways validate and confirm reading this file on each copilot coding agent session:**

# Copilot Instructions for this Flutter/Dart Repository

This repository is a Flutter project, focused on devotional applications and related tools.

## Code Standards

- **Always validate code after changes:**
  - Run `flutter run` or another fast validation command to ensure the project compiles without errors before committing.
  - Fix any compile errors immediately.

- **Test-driven development:**
  - Always run `flutter test` before starting any task and regularly during development.
  - Fix or refactor any failing tests so all tests pass before submitting changes.

- **Keep code clean and formatted:**
  - Use `dart format .` frequently to enforce consistent code style.
  - Use `dart analyze` to keep the codebase clean and resolve warnings/errors.

- **Production code must remain functional:**
  - Do not modify production code unless absolutely necessary for the requested feature or fix.
  - Any modification should be justified in the commit message and, when substantial, documented.

- **BLoC architecture guidelines:**
  - Prefer the BLoC pattern for state and business logic management.
  - For each logical group of BLoCs, create a dedicated folder (e.g., `lib/blocs/auth/`, `lib/blocs/devotional/`).
  - Keep business logic out of UI components; organize by feature and responsibility.

## Development Workflow

- Install dependencies: `flutter pub get`
- Validate compilation: `flutter run`
- Run tests: `flutter test`
- Format code: `dart format .`
- Analyze code: `dart analyze`

## Guidelines

1. Keep the existing project structure and organization.
2. Write unit tests for any new functionality or bugfix.
3. Document public APIs and complex logic.
4. Update documentation in `docs/` or README.md if changes impact usage or structure.

---

**Note for Copilot:**  
Follow these instructions to maintain quality, consistency, and reliability in this repository. Refer to the README.md or ask in Copilot Chat if you need clarification about workflow or standards.
