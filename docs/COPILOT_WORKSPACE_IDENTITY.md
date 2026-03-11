# Copilot Workspace Identity & Session Checklist

> **COPILOT: Read and confirm this file at the START of every session.**
> This is the single source of truth for identifying this workspace and its contingency tooling.

---

## 🗂️ Workspace Fingerprint

| Field                | Value                                                            |
|----------------------|------------------------------------------------------------------|
| **Project name**     | `devocional_nuevo`                                               |
| **Absolute path**    | `/home/develop4god/projects/devocional_nuevo`                    |
| **Platform**         | Pop!_OS 24.04 LTS (Linux, x86_64)                                |
| **Shell**            | bash                                                             |
| **Flutter SDK**      | `/home/develop4god/development/flutter` (channel stable, 3.38.5) |
| **Dart SDK**         | `3.10.4` (bundled with Flutter)                                  |
| **Flutter binary**   | `/home/develop4god/development/flutter/bin/flutter`              |
| **Dart binary**      | `/home/develop4god/development/flutter/bin/dart`                 |
| **Android SDK**      | `/home/develop4god/Android/Sdk`                                  |
| **Primary language** | Dart / Flutter                                                   |
| **Architecture**     | BLoC + Provider                                                  |
| **Min SDK**          | Android API 21                                                   |

---

## ⚠️ Known Terminal Contingency: Subprocess Output Loss

### Problem

When using `run_in_terminal` with **Flutter subprocess commands** (e.g., `flutter test`, 
`flutter build`), `get_terminal_output(id)` returns `null` even with `isBackground=true`. 
This is because Flutter spawns a subprocess that writes asynchronously, and the JetBrains 
terminal integration doesn't capture that async stream.

### Root Cause

The JetBrains AI terminal integration can capture direct shell output but not async 
subprocess streams (Flutter test reporter runs in a subprocess with buffered I/O).

### ✅ Workaround — Redirect to File + Read

For Flutter commands (tests, builds), **redirect output to a temporary file** and read 
the file afterward:

```bash
Step 1: run_in_terminal("flutter test <file> > /tmp/test_output.txt 2>&1", isBackground=true)
Step 2: get_terminal_output(id)  # Returns null (expected)
Step 3: Wait a moment for file I/O
Step 4: run_in_terminal("cat /tmp/test_output.txt", isBackground=true)
Step 5: get_terminal_output(id)  # Returns actual test output
```

### Example — Correct Pattern for Flutter Tests

```bash
# RUN the test, redirect to file:
id = run_in_terminal(
  "cd /home/develop4god/projects/devocional_nuevo && " +
  "/home/develop4god/development/flutter/bin/flutter test test/unit/utils/copyright_utils_test.dart " +
  "--reporter compact > /tmp/test_output.txt 2>&1",
  isBackground=true
)
get_terminal_output(id)  # Returns null (this is OK)

# WAIT a moment for subprocess to complete:
# (Let background process finish naturally, or add explicit wait)

# READ the output file:
id = run_in_terminal("cat /tmp/test_output.txt", isBackground=true)
get_terminal_output(id)  # Returns: "00:02 +5: All tests passed!"
```

### Verified Test Results

✅ Test output successfully captured:
```
00:02 +5: All tests passed!
```

---

## 🔧 Contingency Scripts

Both scripts live at the project root and are executable (`chmod +x`).
They embed the full Flutter binary path so they work regardless of `$PATH`.

| Script      | Purpose                                                     | When to use                    |
|-------------|-------------------------------------------------------------|--------------------------------|
| `errors.sh` | `dart format` + `dart analyze` → saves `analyze_report.txt` | After any lib/ change          |
| `tests.sh`  | Runs a **single targeted** test file (pass as arg)          | When you need test output fast |

### Running the scripts (always background + poll)

```bash
# Analyze:
id = run_in_terminal("cd /home/develop4god/projects/devocional_nuevo && bash errors.sh 2>&1; echo EXIT=$?", isBackground=true)
get_terminal_output(id)

# Test a single file:
id = run_in_terminal("cd /home/develop4god/projects/devocional_nuevo && bash tests.sh test/unit/providers/devocional_provider_test.dart 2>&1; echo EXIT=$?", isBackground=true)
get_terminal_output(id)
```

### Reading the saved analyze report

```bash
id = run_in_terminal("cat /home/develop4god/projects/devocional_nuevo/analyze_report.txt; echo EXIT=$?", isBackground=true)
get_terminal_output(id)
```

---

## 📋 Session Start Checklist (Copilot must do this)

- [ ] Confirm reading this file — state workspace path + OS in first reply
- [ ] Use `isBackground=true` for ALL terminal commands
- [ ] Use `get_terminal_output(id)` to read every result
- [ ] Never pipe `|` inside grep patterns inside shell strings without escaping
- [ ] Run `errors.sh` before and after any `lib/` change
- [ ] Run `tests.sh <file>` on 1-2 targeted files, NOT the full suite

---

## 🧪 Test Strategy (avoid full-suite runner crash)

Running `flutter test` on the entire suite at once hits a Flutter test reporter
crash (`RangeError` in `CompactReporter` / `StateError: LiveTest closed`).

### Safe approach — test by targeted file

```bash
# One file at a time, compact reporter:
flutter test test/unit/providers/devocional_provider_test.dart --reporter compact
flutter test test/unit/providers/localization_provider_test.dart --reporter compact
flutter test test/unit/blocs/devocionales_bloc_test.dart --reporter compact
```

### Key test files to validate after changes

| Change area                       | Test file to run                                            |
|-----------------------------------|-------------------------------------------------------------|
| `devocional_provider.dart`        | `test/unit/providers/devocional_provider_test.dart`         |
| `devocional_provider.dart` (full) | `test/unit/providers/devocional_provider_working_test.dart` |
| `localization_provider.dart`      | `test/unit/providers/localization_provider_test.dart`       |
| `application_language_page.dart`  | `test/unit/providers/devocional_provider_working_test.dart` |
| Any BLoC                          | `test/unit/blocs/<bloc_name>_test.dart`                     |
| TTS service                       | `test/unit/services/tts_service_test.dart`                  |

---

## 📁 Key File Locations

```
lib/
  pages/application_language_page.dart   ← language switching UI
  providers/devocional_provider.dart      ← core state, cache, fetch logic
  providers/localization_provider.dart    ← locale/i18n state
  blocs/                                  ← feature BLoCs
  services/                               ← TTS, analytics, cache, etc.

test/unit/
  providers/                              ← provider unit tests
  blocs/                                  ← bloc unit tests
  services/                               ← service unit tests
  pages/                                  ← page widget tests

.github/copilot-instructions.md          ← coding standards (read each session)
docs/COPILOT_WORKSPACE_IDENTITY.md       ← THIS FILE (read each session)
errors.sh                                ← analyze script (fixed pipe syntax)
tests.sh                                 ← targeted test runner (accepts file arg)
analyze_report.txt                       ← last analyze output (auto-updated)
```

---

## 🔁 Pipe Syntax Reminder for Shell Scripts

The `|` character in grep patterns inside bash scripts **must not be URL-encoded or lost**.

```bash
# CORRECT:
grep -E 'error|warning|info' file.txt

# BROKEN (what happened in original scripts — pipe got dropped):
grep -E 'errorwarninginfo' file.txt
```

Always verify script content with `cat errors.sh` after editing.

