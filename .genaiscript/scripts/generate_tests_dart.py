#!/usr/bin/env python3
"""
Flutter/Dart behavioral test generator focused on real user interaction patterns.

Generates high-quality tests with:
- Proper mock annotations (@GenerateMocks)
- Platform channel mocking
- Async state validation
- Edge case coverage
- Real user behavior scenarios
"""
import os
import subprocess
import pathlib
import json
import re
import requests
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass

ROOT = pathlib.Path(__file__).resolve().parents[2]


@dataclass
class SourceAnalysis:
    """Analysis results from source code inspection."""
    class_name: str
    dependencies: List[str]
    platform_channels: List[str]
    async_methods: List[str]
    state_properties: List[str]
    user_interactions: List[str]
    error_handlers: List[str]


def run(cmd: str, check: bool = True) -> str:
    """Execute shell command and return stdout."""
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(
            f"Command failed: {cmd}\nstdout:{res.stdout}\nstderr:{res.stderr}"
        )
    return res.stdout.strip()


def get_modified_dart_files() -> List[str]:
    """Get list of modified .dart files in lib/ compared to origin/main."""
    try:
        run("git fetch origin main --depth=1", check=False)
    except Exception:
        pass
    out = run("git diff --name-only origin/main...HEAD", check=False)
    files = [f.strip() for f in out.splitlines() if f.strip().endswith(".dart")]
    files = [f for f in files if not f.startswith("test/")]
    files = [f for f in files if f.startswith("lib/")]
    return files


def get_priority_dart_files(max_files: int = 3) -> List[str]:
    """Get high-priority .dart files for test generation."""
    lib_path = ROOT / "lib"
    dart_files = []
    
    # Priority: services > blocs > controllers > providers > models
    priority_folders = ["services", "blocs", "controllers", "providers", "models"]
    
    for folder in priority_folders:
        folder_path = lib_path / folder
        if folder_path.exists():
            for dart_file in folder_path.glob("*.dart"):
                rel_path = str(dart_file.relative_to(ROOT))
                dart_files.append(rel_path)
                if len(dart_files) >= max_files:
                    return dart_files
    
    return dart_files


def read_file(path: str) -> str:
    """Read file content."""
    p = ROOT / path
    return p.read_text(encoding="utf-8")


def analyze_source_code(source: str, file_path: str) -> SourceAnalysis:
    """Analyze source code to extract testable components and user interactions."""
    
    # Extract class name
    class_match = re.search(r'class\s+(\w+)', source)
    class_name = class_match.group(1) if class_match else "UnknownClass"
    
    # Find dependencies (constructor parameters, fields with types)
    dependencies = []
    dep_patterns = [
        r'final\s+(\w+)\s+\w+;',
        r'(\w+)\s+\w+;',
        r'required\s+this\.(\w+)',
    ]
    for pattern in dep_patterns:
        deps = re.findall(pattern, source)
        dependencies.extend([d for d in deps if d[0].isupper()])
    dependencies = list(set(dependencies))
    
    # Find platform channels
    platform_channels = re.findall(r"MethodChannel\(['\"](\w+)['\"]\)", source)
    
    # Find async methods
    async_methods = re.findall(r'Future<\w+>\s+(\w+)\(', source)
    
    # Find state properties
    state_props = []
    state_patterns = [
        r'bool\s+(_?is\w+)',
        r'enum\s+(\w+State)',
        r'(\w+State)\s+\w+',
    ]
    for pattern in state_patterns:
        state_props.extend(re.findall(pattern, source))
    state_props = list(set(state_props))
    
    # Identify user interaction patterns
    user_interactions = []
    interaction_keywords = {
        'speak': 'User initiates speech/audio playback',
        'play': 'User plays audio/video content',
        'pause': 'User pauses playback',
        'stop': 'User stops operation',
        'resume': 'User resumes paused operation',
        'toggle': 'User toggles a setting/state',
        'save': 'User saves data',
        'delete': 'User deletes item',
        'edit': 'User edits content',
        'add': 'User adds new item',
        'update': 'User updates existing data',
        'refresh': 'User refreshes data',
        'load': 'User triggers data loading',
        'download': 'User downloads content',
        'upload': 'User uploads content',
        'share': 'User shares content',
        'favorite': 'User marks as favorite',
        'search': 'User searches content',
        'filter': 'User filters results',
    }
    
    for keyword, description in interaction_keywords.items():
        if re.search(rf'\b{keyword}\w*\s*\(', source, re.IGNORECASE):
            user_interactions.append((keyword, description))
    
    # Find error handling patterns
    error_handlers = []
    if 'try' in source or 'catch' in source:
        error_handlers.append('try_catch_blocks')
    if re.search(r'throw\s+\w+Exception', source):
        error_handlers.append('throws_exceptions')
    if 'onError' in source or 'handleError' in source:
        error_handlers.append('error_callbacks')
    
    return SourceAnalysis(
        class_name=class_name,
        dependencies=dependencies,
        platform_channels=platform_channels,
        async_methods=async_methods,
        state_properties=state_props,
        user_interactions=user_interactions,
        error_handlers=error_handlers,
    )


def generate_channel_mocks(channels: List[str]) -> str:
    """Generate platform channel mock setup code."""
    if not channels:
        return "// No platform channels to mock"
    
    mocks = []
    for channel in channels:
        mocks.append(f"""TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        MethodChannel('{channel}'),
        (call) async {{
          // Mock common methods
          if (call.method == 'speak') return 1;
          if (call.method == 'stop') return 1;
          if (call.method == 'setLanguage') return 1;
          return null;
        }}
      );""")
    return "\n    ".join(mocks)


def generate_channel_cleanup(channels: List[str]) -> str:
    """Generate platform channel cleanup code."""
    if not channels:
        return "// No channels to clean up"
    
    cleanups = []
    for channel in channels:
        cleanups.append(f"""TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(MethodChannel('{channel}'), null);""")
    return "\n    ".join(cleanups)


def build_enhanced_prompt(file_path: str, source: str, analysis: SourceAnalysis) -> str:
    """Build comprehensive prompt with deep source analysis."""
    
    # Build context about the code
    context_parts = []
    
    if analysis.dependencies:
        context_parts.append(f"Dependencies to mock: {', '.join(analysis.dependencies)}")
    
    if analysis.platform_channels:
        context_parts.append(f"Platform channels to mock: {', '.join(analysis.platform_channels)}")
    
    if analysis.async_methods:
        context_parts.append(f"Async methods requiring state validation: {', '.join(analysis.async_methods)}")
    
    if analysis.user_interactions:
        interactions = [f"{kw} ({desc})" for kw, desc in analysis.user_interactions]
        context_parts.append(f"User interactions to test: {', '.join(interactions)}")
    
    context_section = "\n".join(f"- {part}" for part in context_parts) if context_parts else "- Basic unit testing required"
    
    # Build user behavior scenarios
    scenarios = []
    for keyword, description in analysis.user_interactions[:5]:
        scenarios.append(f"""
    test('{description}', () async {{
      // Given: User is ready to {keyword}
      // Setup initial state and mock responses
      
      // When: User performs {keyword} action
      // Trigger the user interaction
      
      // Then: System responds correctly
      // Verify state changes, API calls, UI updates
    }});""")
    
    scenarios_section = "\n".join(scenarios) if scenarios else """
    test('Basic functionality works correctly', () async {
      // Given: Initial state
      // When: User interaction occurs
      // Then: Expected outcome
    });"""
    
    prompt = f"""You are a senior Flutter test engineer specializing in behavioral testing and user interaction patterns.

TARGET FILE: {file_path}
CLASS UNDER TEST: {analysis.class_name}

ANALYZED CONTEXT:
{context_section}

OBJECTIVE: Generate production-quality behavioral tests that validate real user workflows, not just code coverage.

MANDATORY REQUIREMENTS:

1. IMPORTS & ANNOTATIONS:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';
// Import the class under test
import 'package:devocional_nuevo/{file_path.replace('lib/', '')}';

@GenerateMocks([{', '.join(analysis.dependencies[:5]) if analysis.dependencies else 'Object'}])
void main() {{
```

2. SETUP & TEARDOWN PATTERN:
```dart
  late {analysis.class_name} instance;
  late MockDependency mockDep;
  
  setUp(() {{
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Mock platform channels if needed
    {generate_channel_mocks(analysis.platform_channels)}
    
    mockDep = MockDependency();
    instance = {analysis.class_name}(dependency: mockDep);
  }});
  
  tearDown(() {{
    instance.dispose();
    // Clean up platform channel mocks
    {generate_channel_cleanup(analysis.platform_channels)}
  }});
```

3. USER BEHAVIOR TEST STRUCTURE:
Focus on REAL user scenarios, not just method calls. Each test should tell a story:
- What is the user trying to accomplish?
- What actions do they take?
- What do they expect to happen?
- What can go wrong?

EXAMPLE TEST SCENARIOS (adapt to your class):
{scenarios_section}

4. CRITICAL TESTING PATTERNS:

A. ASYNC STATE VALIDATION:
```dart
// When testing async operations
await instance.performAction();
await Future.delayed(Duration(milliseconds: 100)); // Let state propagate

// Then verify BOTH immediate and eventual state
expect(instance.state, expectedState);
expect(instance.isLoading, false);
```

B. ERROR HANDLING:
```dart
test('User sees meaningful error when operation fails', () async {{
  // Given: Network/service failure
  when(mockDep.fetch()).thenThrow(NetworkException('Connection lost'));
  
  // When: User attempts action
  await instance.performAction();
  
  // Then: User sees helpful error message
  expect(instance.hasError, true);
  expect(instance.errorMessage, contains('Connection lost'));
  expect(instance.state, {analysis.class_name}State.error);
}});
```

C. EDGE CASES:
```dart
test('Rapid user clicks are handled gracefully', () async {{
  // Given: User rapidly clicks button
  final futures = List.generate(5, (_) => instance.performAction());
  
  // When: All requests complete
  await Future.wait(futures);
  
  // Then: Only one operation succeeded, others ignored
  verify(mockDep.fetch()).called(1); // Not 5
}});

test('User can recover from error state', () async {{
  // Given: User encountered an error
  await instance.performAction(); // Fails
  expect(instance.hasError, true);
  
  // When: User retries after fixing issue
  when(mockDep.fetch()).thenAnswer((_) async => validData);
  await instance.performAction();
  
  // Then: Error is cleared and operation succeeds
  expect(instance.hasError, false);
  expect(instance.state, {analysis.class_name}State.success);
}});
```

5. PLATFORM CHANNEL MOCKING (if applicable):
```dart
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
  .setMockMethodCallHandler(
    MethodChannel('channel_name'),
    (call) async {{
      switch (call.method) {{
        case 'methodName':
          return expectedValue;
        default:
          return null;
      }}
    }}
  );
```

6. STATE TRANSITION VALIDATION:
If your class has state machines, validate ALL transitions:
```dart
test('Complete user journey through states', () async {{
  // Initial state
  expect(instance.state, {analysis.class_name}State.idle);
  
  // Start operation
  final future = instance.performAction();
  await Future.delayed(Duration(milliseconds: 50));
  expect(instance.state, {analysis.class_name}State.loading);
  
  // Complete operation
  await future;
  expect(instance.state, {analysis.class_name}State.success);
  
  // Reset
  await instance.reset();
  expect(instance.state, {analysis.class_name}State.idle);
}});
```

TEST COVERAGE PRIORITIES:
1. Happy path: User completes their goal successfully
2. Error recovery: User encounters and recovers from errors
3. Edge cases: Empty data, network issues, rapid interactions
4. State management: All state transitions work correctly
5. Resource cleanup: No memory leaks or dangling listeners

SOURCE CODE TO ANALYZE AND TEST:
{source}

CRITICAL: 
- Return ONLY valid Dart code
- No explanations, markdown blocks, or ```dart``` tags
- Start with imports, end with closing braces
- Every test must represent a real user behavior
- Focus on quality over quantity (5-10 excellent tests > 50 trivial ones)
- Make tests fail if the code doesn't meet user expectations

Generate the complete test file now:"""
    return prompt


def extract_dart_code(text: str) -> str:
    """Extract Dart code from response, removing markdown blocks if present."""
    code_block_pattern = r"```(?:dart)?\s*([\s\S]*?)```"
    matches = re.findall(code_block_pattern, text)
    if matches:
        return matches[0].strip()
    
    return text.strip()


def call_gemini_api(prompt: str) -> str:
    """Call Gemini API with enhanced configuration for code generation."""
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("GOOGLE_API_KEY environment variable not set")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-exp")
    
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    
    headers = {"Content-Type": "application/json"}
    
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.0,
            "maxOutputTokens": 8192,
            "topP": 0.95,
            "topK": 40,
            "stopSequences": []
        },
        "safetySettings": [
            {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
            {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
            {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
            {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
        ]
    }
    
    print(f"[INFO] Calling Gemini API: {model}")
    resp = requests.post(url, headers=headers, json=payload, timeout=300)
    
    if resp.status_code != 200:
        error_detail = resp.text[:1000]
        raise Exception(f"API request failed ({resp.status_code}): {error_detail}")
    
    data = resp.json()
    
    if "candidates" in data and data["candidates"]:
        candidate = data["candidates"][0]
        if "content" in candidate and "parts" in candidate["content"]:
            parts = candidate["content"]["parts"]
            text_parts = [p.get("text", "") for p in parts]
            generated = "".join(text_parts)
            return extract_dart_code(generated)
    
    raise Exception(f"Unexpected API response format: {json.dumps(data, indent=2)[:500]}")


def validate_generated_test(content: str, analysis: SourceAnalysis) -> Tuple[bool, List[str]]:
    """Validate generated test meets quality standards."""
    issues = []
    
    required_imports = [
        (r'import.*flutter_test', "Missing flutter_test import"),
        (r'void main\(\)', "Missing main() function"),
        (r'test\(', "No test cases found"),
        (r'expect\(', "No assertions found"),
    ]
    
    for pattern, error in required_imports:
        if not re.search(pattern, content):
            issues.append(error)
    
    if analysis.dependencies and not re.search(r'@GenerateMocks', content):
        issues.append("Missing @GenerateMocks annotation for dependencies")
    
    if analysis.platform_channels and not re.search(r'setMockMethodCallHandler', content):
        issues.append("Missing platform channel mocks")
    
    if analysis.async_methods and not re.search(r'await Future\.delayed', content):
        issues.append("Async methods tested without state propagation delay")
    
    if not re.search(r'setUp\(', content):
        issues.append("Missing setUp() for test initialization")
    
    if not re.search(r'tearDown\(', content):
        issues.append("Missing tearDown() for cleanup")
    
    if 'MissingPluginException' in content:
        issues.append("Generated test contains MissingPluginException - platform channels not mocked")
    
    if re.search(r'expect\([^,]+,\s*true\)', content):
        count = len(re.findall(r'expect\([^,]+,\s*true\)', content))
        if count > 5:
            issues.append(f"Too many trivial boolean assertions ({count}) - needs more meaningful checks")
    
    return len(issues) == 0, issues


def write_test_file(src_path: str, content: str) -> str:
    """Write generated test to appropriate location."""
    rel = src_path.replace("lib/", "").replace("/", "_").replace(".dart", "")
    fname = f"test_behavioral_{rel}.dart"
    out_dir = ROOT / "test" / "behavioral"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / fname
    out_path.write_text(content, encoding="utf-8")
    print(f"[SUCCESS] Test generated: {out_path}")
    return str(out_path)


def main():
    print("[START] Enhanced Flutter/Dart Behavioral Test Generator")
    print("[INFO] Focus: Real user behavior patterns and interaction workflows\n")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-exp")
    print(f"[CONFIG] Model: {model}")
    print(f"[CONFIG] Temperature: 0.0 (deterministic)")
    print(f"[CONFIG] Max tokens: 8192\n")
    
    modified = get_modified_dart_files()
    
    if not modified:
        print("[INFO] No modified files detected")
        print("[INFO] Selecting high-priority files for test generation...\n")
        modified = get_priority_dart_files(max_files=3)
        if not modified:
            print("[WARN] No suitable .dart files found in lib/")
            return
    
    print(f"[INFO] Files to process: {len(modified)}")
    for f in modified:
        print(f"  - {f}")
    print()
    
    generated = []
    failed = []
    
    for idx, file_path in enumerate(modified, 1):
        print(f"[{idx}/{len(modified)}] Processing: {file_path}")
        
        try:
            source = read_file(file_path)
        except Exception as e:
            print(f"  ❌ Failed to read file: {e}\n")
            failed.append((file_path, str(e)))
            continue
        
        print(f"  🔍 Analyzing source code...")
        analysis = analyze_source_code(source, file_path)
        print(f"     Class: {analysis.class_name}")
        print(f"     Dependencies: {len(analysis.dependencies)}")
        print(f"     User interactions: {len(analysis.user_interactions)}")
        print(f"     Async methods: {len(analysis.async_methods)}")
        
        prompt = build_enhanced_prompt(file_path, source, analysis)
        
        print(f"  🤖 Generating behavioral tests...")
        try:
            result = call_gemini_api(prompt)
        except Exception as e:
            print(f"  ❌ API call failed: {e}\n")
            failed.append((file_path, str(e)))
            continue
        
        print(f"  ✓ Validating generated test...")
        is_valid, issues = validate_generated_test(result, analysis)
        
        if not is_valid:
            print(f"  ⚠️  Validation warnings:")
            for issue in issues:
                print(f"     - {issue}")
        
        test_path = write_test_file(file_path, result)
        generated.append(test_path)
        print(f"  ✅ Test file created\n")
    
    print("=" * 60)
    print(f"[SUMMARY] Generation complete")
    print(f"  ✅ Succeeded: {len(generated)}")
    print(f"  ❌ Failed: {len(failed)}")
    
    if generated:
        print(f"\n[NEXT STEPS]")
        print(f"  1. Generate mocks:")
        print(f"     flutter pub run build_runner build --delete-conflicting-outputs")
        print(f"  2. Run tests:")
        print(f"     flutter test test/behavioral/ --reporter expanded")
        print(f"  3. Review test quality and user behavior coverage")
        print(f"  4. Commit tests after manual validation")
    
    if failed:
        print(f"\n[FAILURES]")
        for file_path, error in failed:
            print(f"  - {file_path}: {error}")


if __name__ == "__main__":
    main()
