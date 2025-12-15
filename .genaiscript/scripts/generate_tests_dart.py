#!/usr/bin/env python3
"""
Optimized Flutter/Dart BLoC test generator - Token efficient
Focuses on: BLoC pattern, bloc_test, real user flows
"""
import os
import subprocess
import pathlib
import json
import re
import requests
from typing import List, Dict, Optional
from dataclasses import dataclass

ROOT = pathlib.Path(__file__).resolve().parents[2]


@dataclass
class BlocAnalysis:
    """Lightweight metadata extraction - NO source code sent to LLM"""
    class_name: str
    type: str  # bloc, service, model, provider
    events: List[str]  # For BLoCs only
    states: List[str]  # For BLoCs only
    methods: List[str]
    dependencies: List[str]
    platform_channels: List[str]


def run(cmd: str, check: bool = True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\nstderr:{res.stderr}")
    return res.stdout.strip()


def get_modified_dart_files() -> List[str]:
    """Get modified .dart files in lib/ vs origin/main"""
    try:
        run("git fetch origin main --depth=1", check=False)
    except:
        pass
    out = run("git diff --name-only origin/main...HEAD", check=False)
    files = [f.strip() for f in out.splitlines() if f.strip().endswith(".dart")]
    files = [f for f in files if f.startswith("lib/") and not f.startswith("test/")]
    return files


def get_priority_files(max_files: int = 3) -> List[str]:
    """Select high-priority files for testing"""
    lib_path = ROOT / "lib"
    priority_folders = ["blocs", "services", "providers", "models"]
    
    dart_files = []
    for folder in priority_folders:
        folder_path = lib_path / folder
        if folder_path.exists():
            for dart_file in folder_path.rglob("*.dart"):
                rel_path = str(dart_file.relative_to(ROOT))
                dart_files.append(rel_path)
                if len(dart_files) >= max_files:
                    return dart_files
    return dart_files


def analyze_file(source: str, file_path: str) -> BlocAnalysis:
    """Extract minimal metadata - NO code sent to LLM"""
    
    # Detect class type
    class_match = re.search(r'class\s+(\w+)', source)
    class_name = class_match.group(1) if class_match else "UnknownClass"
    
    file_type = "model"
    if "bloc" in file_path.lower():
        file_type = "bloc"
    elif "service" in file_path.lower():
        file_type = "service"
    elif "provider" in file_path.lower():
        file_type = "provider"
    
    # Extract BLoC events (only for BLoCs)
    events = []
    states = []
    if file_type == "bloc":
        events = re.findall(r'class\s+(\w+Event)\s+extends', source)
        states = re.findall(r'class\s+(\w+State)\s+extends', source)
    
    # Extract public methods
    methods = re.findall(r'(?:Future<\w+>|void|Stream<\w+>)\s+(\w+)\s*\(', source)
    methods = [m for m in methods if not m.startswith('_')][:10]  # Limit
    
    # Dependencies from constructor
    deps = []
    constructor_pattern = r'(?:final|required)\s+(\w+)\s+\w+[;,]'
    for match in re.finditer(constructor_pattern, source):
        dep_type = match.group(1)
        if dep_type[0].isupper() and dep_type not in ['String', 'int', 'bool', 'DateTime']:
            deps.append(dep_type)
    
    # Platform channels
    channels = re.findall(r"MethodChannel\(['\"](\w+)['\"]\)", source)
    
    return BlocAnalysis(
        class_name=class_name,
        type=file_type,
        events=list(set(events))[:5],
        states=list(set(states))[:5],
        methods=methods[:8],
        dependencies=list(set(deps))[:5],
        platform_channels=list(set(channels))[:3]
    )


def build_compact_prompt(file_path: str, analysis: BlocAnalysis) -> str:
    """Compact prompt <800 tokens using project patterns"""
    
    # Template selection based on type
    if analysis.type == "bloc":
        template = """
test('initial state is correct', () {
  expect(bloc.state, isA<{StateInitial}>());
});

blocTest<{ClassName}, {StateName}>(
  'user scenario: [describe user action]',
  build: () => bloc,
  act: (bloc) => bloc.add([EventName]()),
  expect: () => [
    isA<{StateLoading}>(),
    isA<{StateLoaded}>(),
  ],
  verify: (bloc) {
    final state = bloc.state as {StateLoaded};
    expect(state.data, isNotEmpty);
  },
);"""
    else:
        template = """
test('service method works correctly', () async {
  final result = await service.method();
  expect(result, isNotNull);
});"""
    
    prompt = f"""Generate BLoC test for Flutter app using existing patterns.

FILE: {file_path}
CLASS: {analysis.class_name}
TYPE: {analysis.type}

METADATA:
- Events: {', '.join(analysis.events) if analysis.events else 'N/A'}
- States: {', '.join(analysis.states) if analysis.states else 'N/A'}  
- Methods: {', '.join(analysis.methods[:5])}
- Dependencies: {', '.join(analysis.dependencies)}
- Channels: {', '.join(analysis.platform_channels) if analysis.platform_channels else 'None'}

REQUIREMENTS:
1. Use bloc_test for BLoCs
2. Mock SharedPreferences: SharedPreferences.setMockInitialValues({{}})
3. Mock platform channels if needed
4. Focus on user scenarios, not code coverage
5. Use stream.firstWhere for async validation

IMPORTS REQUIRED:
```dart
import 'package:flutter_test/flutter_test.dart';
{"import 'package:bloc_test/bloc_test.dart';" if analysis.type == "bloc" else ""}
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/{file_path.replace('lib/', '')}';
```

SETUP PATTERN:
```dart
setUp(() {{
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({{}});
  {"// Mock platform channels" if analysis.platform_channels else ""}
  {f"// Mock dependencies: {', '.join(analysis.dependencies[:3])}" if analysis.dependencies else ""}
}});
```

TEMPLATE:
{template}

Generate 5-8 focused tests covering:
- Initial state
- Main user flows (2-3 tests)
- Error handling (1 test)
- Edge cases (1-2 tests)

Return ONLY valid Dart code, no markdown."""
    
    return prompt


def call_gemini(prompt: str) -> str:
    """Call Gemini with optimized settings"""
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("GOOGLE_API_KEY not set")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-exp")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.1,  # More deterministic
            "maxOutputTokens": 4096,
            "topP": 0.95,
            "topK": 40,
        },
        "safetySettings": [
            {"category": cat, "threshold": "BLOCK_NONE"}
            for cat in ["HARM_CATEGORY_HARASSMENT", "HARM_CATEGORY_HATE_SPEECH", 
                       "HARM_CATEGORY_SEXUALLY_EXPLICIT", "HARM_CATEGORY_DANGEROUS_CONTENT"]
        ]
    }
    
    resp = requests.post(url, json=payload, timeout=120)
    if resp.status_code != 200:
        raise Exception(f"API error ({resp.status_code}): {resp.text[:500]}")
    
    data = resp.json()
    if "candidates" not in data or not data["candidates"]:
        raise Exception(f"No candidates in response: {json.dumps(data)[:300]}")
    
    text = data["candidates"][0]["content"]["parts"][0]["text"]
    
    # Remove markdown fences
    text = re.sub(r'```dart\s*', '', text)
    text = re.sub(r'```\s*', '', text)
    return text.strip()


def validate_test(content: str, analysis: BlocAnalysis) -> tuple[bool, List[str]]:
    """Validate generated test quality"""
    issues = []
    
    # Required imports
    if "import 'package:flutter_test/flutter_test.dart';" not in content:
        issues.append("Missing flutter_test import")
    
    if analysis.type == "bloc" and "bloc_test" not in content:
        issues.append("BLoC test missing bloc_test import")
    
    # Setup requirements
    if "setUp(" not in content:
        issues.append("Missing setUp")
    if "TestWidgetsFlutterBinding.ensureInitialized()" not in content:
        issues.append("Missing binding initialization")
    
    # Test structure
    if content.count("test(") + content.count("blocTest") < 3:
        issues.append("Less than 3 tests generated")
    
    if "expect(" not in content:
        issues.append("No assertions found")
    
    # BLoC specific
    if analysis.type == "bloc":
        if not re.search(r'blocTest<\w+,\s*\w+>', content):
            issues.append("BLoC test missing blocTest usage")
    
    return len(issues) == 0, issues


def write_test_file(src_path: str, content: str, analysis: BlocAnalysis) -> str:
    """Write test to appropriate location"""
    test_dir = ROOT / "test" / "behavioral"
    test_dir.mkdir(parents=True, exist_ok=True)
    
    # Naming: {type}_{class_name}_test.dart
    filename = f"{analysis.type}_{analysis.class_name.lower()}_test.dart"
    out_path = test_dir / filename
    
    out_path.write_text(content, encoding="utf-8")
    return str(out_path)


def main():
    print("[START] Optimized BLoC Test Generator")
    print(f"[CONFIG] Model: {os.getenv('GENAI_MODEL', 'gemini-2.0-flash-exp')}")
    print(f"[CONFIG] Strategy: Metadata-only prompts (<1000 tokens)\n")
    
    # Get files to process
    modified = get_modified_dart_files()
    if not modified:
        print("[INFO] No modified files, selecting priority files...")
        modified = get_priority_files(max_files=3)
    
    if not modified:
        print("[WARN] No files found")
        return
    
    print(f"[INFO] Processing {len(modified)} files:")
    for f in modified:
        print(f"  - {f}")
    print()
    
    generated = []
    failed = []
    
    for idx, file_path in enumerate(modified, 1):
        print(f"[{idx}/{len(modified)}] {file_path}")
        
        try:
            source = (ROOT / file_path).read_text(encoding="utf-8")
        except Exception as e:
            print(f"  ❌ Read error: {e}\n")
            failed.append((file_path, str(e)))
            continue
        
        # Analyze (no LLM)
        print(f"  🔍 Analyzing...")
        analysis = analyze_file(source, file_path)
        print(f"     Type: {analysis.type}, Methods: {len(analysis.methods)}")
        
        # Generate test
        prompt = build_compact_prompt(file_path, analysis)
        token_estimate = len(prompt.split())
        print(f"  📤 Sending prompt (~{token_estimate} tokens)...")
        
        try:
            result = call_gemini(prompt)
        except Exception as e:
            print(f"  ❌ API error: {e}\n")
            failed.append((file_path, str(e)))
            continue
        
        # Validate
        print(f"  ✓ Validating...")
        is_valid, issues = validate_test(result, analysis)
        if not is_valid:
            print(f"  ⚠️  Issues: {', '.join(issues[:3])}")
        
        # Write
        test_path = write_test_file(file_path, result, analysis)
        generated.append(test_path)
        print(f"  ✅ {os.path.basename(test_path)}\n")
    
    print("=" * 60)
    print(f"[SUMMARY] ✅ {len(generated)} | ❌ {len(failed)}")
    
    if generated:
        print(f"\n[NEXT] Run: flutter pub run build_runner build")
        print(f"       Then: flutter test test/behavioral/")
    
    if failed:
        print(f"\n[FAILED]")
        for path, err in failed:
            print(f"  - {path}: {err[:80]}")


if __name__ == "__main__":
    main()
