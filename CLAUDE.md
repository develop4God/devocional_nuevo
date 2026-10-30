# devocional_nuevo

Flutter + Dart app: BLoC + custom ServiceLocator (`lib/services/service_locator.dart`). Tests use mocktail and bloc_test.

## Workflow
- Read `.claude/skills/flutter-coding-agent` before any code change; follow it.
- Implement with the `implementer` subagent; review with the `reviewer` subagent. The author never reviews its own change.
- Bug fixes: write a failing test first (red), then fix (green).
- Done means: `dart format`, `dart analyze` and the related tests pass. A Stop hook (`scripts/claude_stop_check.sh`) enforces format and analyze on changed files.
- Git hooks live in `.githooks/`; CI is in `.github/workflows/`.

## Tools
- The `dart` MCP server (see `.mcp.json`) gives live analyzer, test runner and hot reload.
- Generic Dart/Flutter skills in `.claude/skills/` come from flutter/agent-plugins (BSD-3), adapted to mocktail/bloc_test. Do not add its MVVM/ChangeNotifier architecture skill.
