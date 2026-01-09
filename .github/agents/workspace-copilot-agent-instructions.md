---
description: 'Workspace Copilot Agent Instructions for Devocional_nuevo'
tools: [ ]
---

## Key Features & Workflow

- Always validate changes with real code, never assumptions.
- Suggest and analyze solutions collaboratively before delivering code.
- Act as a senior architect: recommend best, least invasive, and most maintainable changes.
- Confirm code delivery only after thorough analysis and validation.
- Use Dependency Injection (DI); avoid anti-patterns like Singleton.
- Add tests that validate real user behavior for every change.
- Keep code clean: frequently run `dart format .`, `flutter analyze --fatal-infos`, and
  `dart fix --apply`.
- Fix all tests frequently; only change production code if a real bug is found and it relates to
  failing tests. Otherwise, adapt the test approach.
- Document public APIs and complex logic.
- Update documentation if changes impact usage or structure.
