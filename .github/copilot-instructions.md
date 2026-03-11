- **copilot allways validate and confirm reading this file on each copilot coding agent session:**
- **copilot also read `docs/COPILOT_WORKSPACE_IDENTITY.md` on each session — it contains the
  workspace fingerprint and the terminal contingency workaround.**

# Copilot Instructions for this Flutter/Dart Repository

## Code Standards

- **Always validate code after changes:**
    - Run `flutter run` or another fast validation command to ensure the project compiles without
      errors before committing.
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
    - For each logical group of BLoCs, create a dedicated folder (e.g., `lib/blocs/auth/`,
      `lib/blocs/devotional/`).
    - Keep business logic out of UI components; organize by feature and responsibility.

## Development Workflow

- Install dependencies: `flutter pub get`
- Validate compilation: `flutter run`
- Run tests: `flutter test`
- Format code: `dart format .`
- Analyze code: `dart analyze`

## ⚠️ Terminal Contingency (CRITICAL)

**Flutter subprocess commands** (e.g., `flutter test`, `flutter build`) return `null` from 
`get_terminal_output(id)` because they spawn async subprocesses that the JetBrains terminal 
can't capture.

**For Flutter commands: redirect output to file, then read the file:**

```bash
# Step 1: Run command with output redirected to file
id = run_in_terminal(
  "cd /home/develop4god/projects/devocional_nuevo && " +
  "/home/develop4god/development/flutter/bin/flutter test <file> " +
  "--reporter compact > /tmp/test_output.txt 2>&1",
  isBackground=true
)
get_terminal_output(id)  # Returns null (expected for subprocesses)

# Step 2: Read the output file after subprocess completes
id = run_in_terminal("cat /tmp/test_output.txt", isBackground=true)
get_terminal_output(id)  # Returns actual test output
```

**For direct shell commands** (echo, ls, cat, etc.), output is captured normally:

```bash
id = run_in_terminal("echo 'test' && pwd", isBackground=true)
get_terminal_output(id)  # Returns output immediately
```

For analysis/tests, use the project scripts with this pattern:

```bash
# Analyze:
bash errors.sh 2>&1; echo EXIT=$?

# Test ONE file (never run full suite — reporter crashes):
bash tests.sh test/unit/providers/devocional_provider_test.dart 2>&1; echo EXIT=$?
```

See `docs/COPILOT_WORKSPACE_IDENTITY.md` for full details.

## Guidelines

1. Keep the existing project structure and organization.
2. Write unit tests for any new functionality or bugfix.
3. Document public APIs and complex logic.
4. Update documentation in `docs/` or README.md if changes impact usage or structure.

---

**Note for Copilot:**  
Follow these instructions to maintain quality, consistency, and reliability in this repository.
