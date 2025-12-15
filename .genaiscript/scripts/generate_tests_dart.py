#!/usr/bin/env python3
"""
Optimized Flutter/Dart BLoC test generator - Token efficient
Focuses on: BLoC pattern, bloc_test, coverage gaps
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
    """Lightweight metadata extraction"""
    class_name: str
    type: str
    events: List[str]
    states: List[str]
    methods: List[str]
    dependencies: List[str]
    platform_channels: List[str]


def run(cmd: str, check: bool = True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\nstderr:{res.stderr}")
    return res.stdout.strip()


def get_modified_dart_files() -> List[str]:
    try:
        run("git fetch origin main --depth=1", check=False)
    except:
        pass
    out = run("git diff --name-only origin/main...HEAD", check=False)
    files = [f.strip() for f in out.splitlines() if f.strip().endswith(".dart")]
    files = [f for f in files if f.startswith("lib/") and not f.startswith("test/")]
    return files


def get_priority_files(max_files: int = 3) -> List[str]:
    lib_path = ROOT / "lib"
    priority_folders = ["blocs", "services", "providers", "models"]
    
    exclude_patterns = ['_event.dart', '_state.dart', '_models.dart', 
                       '.g.dart', '.freezed.dart']
    
    dart_files = []
    for folder in priority_folders:
        folder_path = lib_path / folder
        if folder_path.exists():
            for dart_file in folder_path.rglob("*.dart"):
                rel_path = str(dart_file.relative_to(ROOT))
                if any(pattern in rel_path for pattern in exclude_patterns):
                    continue
                dart_files.append(rel_path)
                if len(dart_files) >= max_files:
                    return dart_files
    return dart_files


def get_existing_test_coverage(file_path: str) -> dict:
    """Check what's already tested - FREE, no tokens"""
    base_name = pathlib.Path(file_path).stem
    
    covered_scenarios = set()
    test_dir = ROOT / "test"
    
    if test_dir.exists():
        for test_file in test_dir.rglob(f"*{base_name}*.dart"):
            try:
                content = test_file.read_text()
                test_names = re.findall(r"test\(['\"](.+?)['\"]", content)
                test_names += re.findall(r"blocTest<[^>]+>\(['\"](.+?)['\"]", content)
                covered_scenarios.update(test_names)
            except:
                pass
    
    return {
        'has_tests': len(covered_scenarios) > 0,
        'test_count': len(covered_scenarios),
        'scenarios': list(covered_scenarios)
    }


def analyze_file(source: str, file_path: str) -> BlocAnalysis:
    """Extract minimal metadata - NO code sent to LLM"""
    
    class_match = re.search(r'class\s+(\w+)', source)
    class_name = class_match.group(1) if class_match else "UnknownClass"
    
    file_type = "model"
    if "bloc" in file_path.lower() and not any(x in file_path for x in ['_event', '_state']):
        file_type = "bloc"
    elif "service" in file_path.lower():
        file_type = "service"
    elif "provider" in file_path.lower():
        file_type = "provider"
    
    events = []
    states = []
    if file_type == "bloc":
        base_path = pathlib.Path(file_path).parent
        bloc_name = class_name.replace('Bloc', '').lower()
        
        event_file = ROOT / base_path / f"{bloc_name}_event.dart"
        if event_file.exists():
            event_src = event_file.read_text()
            events = re.findall(r'class\s+(\w+)\s+extends\s+\w+Event', event_src)
        
        state_file = ROOT / base_path / f"{bloc_name}_state.dart"
        if state_file.exists():
            state_src = state_file.read_text()
            states = re.findall(r'class\s+(\w+)\s+extends\s+\w+State', state_src)
    
    methods = re.findall(r'(?:Future<\w+>|void|Stream<\w+>)\s+(\w+)\s*\(', source)
    methods = [m for m in methods if not m.startswith('_')][:10]
    
    deps = []
    constructor_pattern = r'(?:final|required)\s+(\w+)\s+\w+[;,)]'
    for match in re.finditer(constructor_pattern, source):
        dep_type = match.group(1)
        if dep_type[0].isupper() and dep_type not in ['String', 'int', 'bool', 'DateTime', 'List', 'Map']:
            deps.append(dep_type)
    
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


def build_compact_prompt(file_path: str, analysis: BlocAnalysis, coverage: dict) -> Optional[str]:
    """Compact prompt using project patterns"""
    
    if coverage['test_count'] >= 5:
        return None
    
    existing_tests = '\n'.join(f"- {s}" for s in coverage['scenarios'][:10])
    
    if analysis.type == "bloc":
        events_str = ', '.join(analysis.events) if analysis.events else 'LoadEvents'
        states_str = ', '.join(analysis.states) if analysis.states else 'Initial, Loading, Loaded'
        
        prompt = f"""Generate NEW Flutter BLoC tests (avoid duplicates).

FILE: {file_path}
BLOC: {analysis.class_name}
EVENTS: {events_str}
STATES: {states_str}

EXISTING TESTS ({coverage['test_count']}):
{existing_tests if coverage['has_tests'] else '(None - first tests)'}

REQUIRED: Generate tests for UNTESTED scenarios only.

IMPORTS:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:devocional_nuevo/{file_path.replace('lib/', '')}';
```

SETUP:
```dart
late {analysis.class_name} bloc;

setUp(() {{
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({{}});
  bloc = {analysis.class_name}();
}});

tearDown(() => bloc.close());
```

Generate 3-5 NEW tests using real events: {events_str}
Return ONLY Dart code, no markdown."""
        return prompt
    
    return None


def call_gemini(prompt: str) -> str:
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("GOOGLE_API_KEY not set")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-lite")
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.1,
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
        raise Exception(f"No candidates: {json.dumps(data)[:300]}")
    
    text = data["candidates"][0]["content"]["parts"][0]["text"]
    text = re.sub(r'```dart\s*', '', text)
    text = re.sub(r'```\s*', '', text)
    return text.strip()


def validate_test(content: str, analysis: BlocAnalysis) -> tuple[bool, List[str]]:
    issues = []
    
    if "import 'package:flutter_test/flutter_test.dart';" not in content:
        issues.append("Missing flutter_test import")
    
    if analysis.type == "bloc" and "bloc_test" not in content:
        issues.append("BLoC missing bloc_test")
    
    if "setUp(" not in content:
        issues.append("Missing setUp")
    
    if content.count("test(") + content.count("blocTest") < 2:
        issues.append("Less than 2 tests")
    
    return len(issues) == 0, issues


def write_test_file(src_path: str, content: str, analysis: BlocAnalysis) -> str:
    test_dir = ROOT / "test" / "behavioral"
    test_dir.mkdir(parents=True, exist_ok=True)
    
    class_name = analysis.class_name.lower()
    if class_name.endswith('bloc'):
        class_name = class_name[:-4]
    
    filename = f"{analysis.type}_{class_name}_behavioral_test.dart"
    out_path = test_dir / filename
    
    out_path.write_text(content, encoding="utf-8")
    return str(out_path)


def main():
    print("[START] Optimized BLoC Test Generator")
    print(f"[CONFIG] Model: {os.getenv('GENAI_MODEL', 'gemini-2.0-flash-lite')}")
    print(f"[CONFIG] Strategy: Coverage-aware generation\n")
    
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
    skipped = []
    failed = []
    
    for idx, file_path in enumerate(modified, 1):
        print(f"[{idx}/{len(modified)}] {file_path}")
        
        try:
            source = (ROOT / file_path).read_text(encoding="utf-8")
        except Exception as e:
            print(f"  ❌ Read error: {e}\n")
            failed.append((file_path, str(e)))
            continue
        
        print(f"  🔍 Analyzing...")
        analysis = analyze_file(source, file_path)
        coverage = get_existing_test_coverage(file_path)
        print(f"     Type: {analysis.type}, Existing tests: {coverage['test_count']}")
        
        if coverage['test_count'] >= 5:
            print(f"  ⏭️  Skipped (already has {coverage['test_count']} tests)\n")
            skipped.append(file_path)
            continue
        
        prompt = build_compact_prompt(file_path, analysis, coverage)
        if prompt is None:
            print(f"  ⏭️  Skipped (sufficient coverage)\n")
            skipped.append(file_path)
            continue
        
        token_estimate = len(prompt.split())
        print(f"  📤 Sending prompt (~{token_estimate} tokens)...")
        
        try:
            result = call_gemini(prompt)
        except Exception as e:
            print(f"  ❌ API error: {e}\n")
            failed.append((file_path, str(e)))
            continue
        
        print(f"  ✓ Validating...")
        is_valid, issues = validate_test(result, analysis)
        if not is_valid:
            print(f"  ⚠️  Issues: {', '.join(issues[:2])}")
        
        test_path = write_test_file(file_path, result, analysis)
        generated.append(test_path)
        print(f"  ✅ {os.path.basename(test_path)}\n")
    
    print("=" * 60)
    print(f"[SUMMARY] ✅ {len(generated)} | ⏭️  {len(skipped)} | ❌ {len(failed)}")
    
    if generated:
        print(f"\n[NEXT] Run: flutter test test/behavioral/")
    
    if failed:
        print(f"\n[FAILED]")
        for path, err in failed:
            print(f"  - {path}: {err[:80]}")


if __name__ == "__main__":
    main()
