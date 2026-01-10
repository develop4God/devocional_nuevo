# Manual Test Script Documentation

This document explains the purpose, usage, and structure of the `manual_test_script.sh` file in this
repository.

---

## Purpose: Migration & Legacy Data Validation

The primary use of `manual_test_script.sh` is to validate data migrations and legacy user
functionalities (such as saved favorites)
when updating the app. The script simulates a real production update scenario, ensuring that user
data is preserved across app
upgrades. This is crucial because the default `flutter run` or Android Studio behavior may delete or
override app data,
which does not reflect the real user experience during an update from the Play Store or other
distribution channels.

**Key goals:**

- Ensure that user data (favorites, settings, etc.) is retained after updating the app.
- Validate migration logic and legacy data handling.
- Simulate production-like update scenarios for robust testing.

---

## Overview

`manual_test_script.sh` is a Bash script designed to automate and standardize manual testing tasks
for the Devocional_nuevo Flutter project. It provides a set of commands and checks to help
developers and testers validate the app's behavior, environment, and build process efficiently, with
a special focus on migration and legacy data validation.

---

## Usage

Run the script from the project root directory:

```bash
bash manual_test_script.sh
```

Some commands may require additional permissions (e.g., `chmod +x manual_test_script.sh`).

**Migration/Upgrade Testing Tips:**

- Install a previous version of the app (e.g., from an APK or Play Store) and use it to save
  favorites or other user data.
- Run this script to build and install the new version without uninstalling the old one, ensuring
  user data is preserved.
- Verify that all legacy data and features (e.g., saved favorites) are still available and
  functional after the update.

---

## Main Features

- **Environment Validation:**
    - Checks for required tools (Flutter, Dart, Java, etc.).
    - Verifies environment variables and system configuration.
- **Dependency Management:**
    - Runs `flutter pub get` to fetch dependencies.
    - Optionally cleans and upgrades packages.
- **Build & Run:**
    - Supports building APKs and running the app on connected devices or emulators.
- **Testing:**
    - Runs unit and integration tests using `flutter test` and other commands.
- **Linting & Formatting:**
    - Runs `dart format .` and `dart analyze` to ensure code quality.
- **Custom Checks:**
    - Includes project-specific checks and manual test steps.

---

## Script Structure

- **Variable Declarations:**
    - Defines paths, colors for output, and helper variables.
- **Helper Functions:**
    - Functions for colored output, error handling, and repeated tasks.
- **Main Logic:**
    - Sequentially executes environment checks, dependency management, build, test, and custom
      steps.
- **Manual Test Prompts:**
    - Prompts the user for manual verification of certain features or UI elements.

---

## Customization

You can add or modify steps in the script to fit new manual test cases or project requirements.
Follow the existing structure for consistency.

---

## Best Practices

- Run this script before submitting code or releases.
- Address any errors or warnings reported by the script.
- Update the script and this documentation if new manual test steps are added.

---

## Troubleshooting

- Ensure all required tools are installed and available in your PATH.
- If you encounter permission errors, run `chmod +x manual_test_script.sh`.
- Review script output for specific error messages and suggested fixes.

---

## Contact

For questions or improvements, contact the repository maintainers or open an issue.
