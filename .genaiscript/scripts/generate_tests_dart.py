#!/usr/bin/env python3
"""
Flutter/Dart QUALITY test generator using LLM (Gemini via GOOGLE_API_KEY).
Focus: Real user behavior, integration tests, avoiding implementation details.
"""
import os
import subprocess
import pathlib
import json
import re
import requests
from typing import List, Dict, Optional, Tuple

ROOT = pathlib.Path(__file__).resolve().parents[2]

# ============================================================================
# QUALITY VALIDATION RULES
# ============================================================================

ANTI_PATTERNS = {
    'mock_build_context': r'class\s+Mock\w*Context\s+extends\s+Mock\s+implements\s+BuildContext',
    'contradictory_verify': r'verify\([^)]+\)\.called\(0\)',
    'placeholder_imports': r'import\s+[\'"]package:your_app/',
    'admits_difficulty': r'//.*tricky to test|//.*hard to test',
    'excessive_mocking': r'(Mock\w+\s+extends\s+Mock\s+implements){4,}',  # 4+ mocks = smell
    'testing_privates': r'InAppReviewService\._\w+Key',  # Accessing private members
}

QUALITY_PATTERNS = {
    'user_flow_test': r'testWidgets\([\'"][Uu]ser\s+',
    'integration_test': r'await\s+tester\.pumpWidget',
    'real_bloc_usage': r'BlocProvider<\w+>',
    'proper_mock_setup': r'SharedPreferences\.setMockInitialValues',
    'meaningful_assertions': r'expect\(find\.\w+,\s*finds',
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

def run(cmd: str, check: bool = True) -> str:
    """Run a shell command and return stdout."""
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\nstderr:{res.stderr}")
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

def get_sample_dart_files(max_files: int = 3) -> List[str]:
    """Get sample .dart files from lib/ when no modified files are found."""
    lib_path = ROOT / "lib"
    dart_files = []
    priority_folders = ["services", "blocs", "widgets", "pages"]
    
    for folder in priority_folders:
        folder_path = lib_path / folder
        if folder_path.exists():
            for dart_file in folder_path.glob("*.dart"):
                rel_path = str(dart_file.relative_to(ROOT))
                dart_files.append(rel_path)
                if len(dart_files) >= max_files:
                    return dart_files
    
    if len(dart_files) < max_files:
        for dart_file in lib_path.rglob("*.dart"):
            rel_path = str(dart_file.relative_to(ROOT))
            if rel_path not in dart_files:
                dart_files.append(rel_path)
                if len(dart_files) >= max_files:
                    break
    return dart_files

def read_file(path: str) -> str:
    """Read file content."""
    p = ROOT / path
    return p.read_text(encoding="utf-8")

def get_best_test_examples() -> str:
    """Extract examples from existing high-quality tests."""
    examples = []
    test_dir = ROOT / "test" / "integration"
    
    if test_dir.exists():
        for test_file in test_dir.glob("*.dart"):
            content = test_file.read_text(encoding="utf-8")
            # Extract first test as example
            match = re.search(r'testWidgets\([^{]+\{[^}]+\}', content, re.DOTALL)
            if match:
                examples.append(f"// From {test_file.name}\n{match.group()}")
                if len(examples) >= 2:
                    break
    
    return "\n\n".join(examples) if examples else "No examples available"

def analyze_file_type(file_path: str, content: str) -> str:
    """Determine what type of file this is for specialized testing."""
    if 'bloc.dart' in file_path.lower():
        return 'bloc'
    elif 'service.dart' in file_path.lower():
        return 'service'
    elif 'page.dart' in file_path.lower() or 'screen.dart' in file_path.lower():
        return 'page'
    elif 'widget' in file_path.lower():
        return 'widget'
    elif 'model.dart' in file_path.lower():
        return 'model'
    else:
        return 'unknown'

# ============================================================================
# ENHANCED PROMPT ENGINEERING
# ============================================================================

def build_prompt(file_path: str, source: str) -> str:
    """Build enhanced prompt with quality guidelines and examples."""
    
    file_type = analyze_file_type(file_path, source)
    test_examples = get_best_test_examples()
    
    prompt = f"""You are a SENIOR Flutter/Dart test architect. Your mission: Generate HIGH-QUALITY behavioral tests that validate REAL USER SCENARIOS, not implementation details.

🎯 TARGET FILE: {file_path}
📦 TYPE: {file_type}

═══════════════════════════════════════════════════════════════
🚫 CRITICAL: NEVER DO THESE (Anti-Patterns)
═══════════════════════════════════════════════════════════════

1. ❌ NEVER mock BuildContext:
   // BAD:
   class MockBuildContext extends Mock implements BuildContext {{}}
   
   // GOOD:
   testWidgets('test name', (tester) async {{
     final context = tester.element(find.byType(MyWidget));
   }});

2. ❌ NEVER use contradictory assertions:
   // BAD:
   testWidgets('should call X when Y', ...) {{
     verify(mockService.X()).called(0); // ❌ Says "should call" but verifies 0 calls
   }}
   
   // GOOD:
   testWidgets('should call X when Y', ...) {{
     verify(mockService.X()).called(1);
   }});

3. ❌ NEVER use placeholder imports:
   // BAD:
   import 'package:your_app/services/...'; // ❌
   
   // GOOD:
   import 'package:devocional_nuevo/services/...';

4. ❌ NEVER test private implementation details:
   // BAD:
   verify(prefs.setBool(Service._privateKey, true)); // ❌
   
   // GOOD:
   expect(service.isConfigured, true); // Test public API

5. ❌ NEVER over-mock (4+ mocks = code smell):
   // BAD:
   MockA, MockB, MockC, MockD, MockE... // ❌ Too many dependencies
   
   // GOOD: Use real objects or refactor the code

═══════════════════════════════════════════════════════════════
✅ REQUIRED: Quality Patterns to Follow
═══════════════════════════════════════════════════════════════

1. ✅ ALWAYS write integration/widget tests (80% of tests):
   testWidgets('User creates thanksgiving and sees it in list', (tester) async {{
     await tester.pumpWidget(
       MaterialApp(
         home: BlocProvider(
           create: (_) => ThanksgivingBloc(),
           child: ThanksgivingsPage(),
         ),
       ),
     );
     
     // GIVEN: Initial state
     expect(find.text('No thanksgivings'), findsOneWidget);
     
     // WHEN: User adds thanksgiving
     await tester.tap(find.byIcon(Icons.add));
     await tester.pumpAndSettle();
     await tester.enterText(find.byType(TextField), 'Thank God for health');
     await tester.tap(find.text('Save'));
     await tester.pumpAndSettle();
     
     // THEN: Verify outcome
     expect(find.text('Thank God for health'), findsOneWidget);
   }});

2. ✅ Use REAL dependencies when possible:
   // GOOD: Real SharedPreferences
   setUp(() async {{
     SharedPreferences.setMockInitialValues({{}});
     prefs = await SharedPreferences.getInstance();
   }});

3. ✅ Test USER BEHAVIORS, not methods:
   // BAD: "test saveData() method"
   // GOOD: "User saves data and sees success message"

4. ✅ Use descriptive Given-When-Then structure:
   test('User flow: create, edit, delete thanksgiving', () async {{
     // Given: Fresh state
     final bloc = ThanksgivingBloc();
     
     // When: User creates thanksgiving
     bloc.add(AddThanksgiving('Test'));
     await expectLater(bloc.stream, emits(isA<ThanksgivingAdded>()));
     
     // Then: Verify state
     expect(bloc.state.thanksgivings.length, 1);
   }});

5. ✅ Setup localization properly if using .tr():
   testWidgets('...', (tester) async {{
     await tester.pumpWidget(
       EasyLocalization(
         supportedLocales: [Locale('en'), Locale('es')],
         path: 'i18n',
         fallbackLocale: Locale('en'),
         child: MaterialApp(home: MyWidget()),
       ),
     );
   }});

═══════════════════════════════════════════════════════════════
📚 EXAMPLES FROM YOUR PROJECT (Learn from these)
═══════════════════════════════════════════════════════════════

{test_examples}

═══════════════════════════════════════════════════════════════
🎯 SPECIFIC GUIDANCE FOR {file_type.upper()}
═══════════════════════════════════════════════════════════════
"""

    # Add type-specific guidance
    if file_type == 'bloc':
        prompt += """
For BLoCs:
- Focus on event → state transitions
- Test real user flows (e.g., "User adds prayer → sees in active list → marks answered → moves to answered tab")
- Use bloc_test package for complex scenarios
- Don't mock the BLoC itself, test it directly
"""
    elif file_type == 'service':
        prompt += """
For Services:
- Test public API methods with real-world scenarios
- Mock only external dependencies (HTTP, platform channels)
- Test error handling and edge cases
- Use integration tests to verify service interactions
"""
    elif file_type == 'page' or file_type == 'widget':
        prompt += """
For Pages/Widgets:
- ALWAYS use testWidgets() for UI components
- Test complete user journeys (navigation, input, feedback)
- Verify UI updates after state changes
- Test accessibility (semantic labels, contrast)
"""

    prompt += f"""
═══════════════════════════════════════════════════════════════
📝 YOUR TASK
═══════════════════════════════════════════════════════════════

Generate 2-4 HIGH-QUALITY behavioral tests for this file.

PRIORITY ORDER:
1. Most critical user flow (happy path)
2. Most common error scenario
3. Edge case that could break UX
4. Accessibility or performance concern

REQUIREMENTS:
✓ Return ONLY valid Dart code (no markdown, no explanations)
✓ Start with proper imports (use 'devocional_nuevo' package name)
✓ Use meaningful test names that describe user behavior
✓ Include setUp/tearDown if needed
✓ Each test should be 15-30 lines (complete but focused)
✓ Avoid testing implementation details

SOURCE CODE TO TEST:
════════════════════════════════════════════════════════════════

{source}

════════════════════════════════════════════════════════════════
Generate the complete test file now (ONLY Dart code):
"""
    
    return prompt

# ============================================================================
# QUALITY VALIDATION
# ============================================================================

def validate_test_quality(test_code: str) -> Tuple[bool, List[str], int]:
    """
    Validate generated test code quality.
    Returns: (is_valid, issues, quality_score)
    """
    issues = []
    quality_score = 10  # Start with perfect score
    
    # Check for anti-patterns (each violation = -2 points)
    for pattern_name, pattern in ANTI_PATTERNS.items():
        if re.search(pattern, test_code):
            issues.append(f"❌ Anti-pattern detected: {pattern_name}")
            quality_score -= 2
    
    # Check for quality patterns (missing patterns = -1 point each)
    quality_found = 0
    for pattern_name, pattern in QUALITY_PATTERNS.items():
        if re.search(pattern, test_code):
            quality_found += 1
    
    if quality_found < 2:
        issues.append(f"⚠️ Only {quality_found} quality patterns found (expected 2+)")
        quality_score -= (2 - quality_found)
    
    # Check for imports
    if not re.search(r'import\s+[\'"]package:devocional_nuevo/', test_code):
        issues.append("⚠️ Missing proper package imports")
        quality_score -= 1
    
    # Check for test structure
    if not re.search(r'void main\(\)', test_code):
        issues.append("❌ Missing main() function")
        quality_score -= 2
    
    if not re.search(r'test(Widgets)?\(', test_code):
        issues.append("❌ No test() or testWidgets() found")
        quality_score -= 3
    
    # Bonus points for good practices
    if re.search(r'// GIVEN:|// WHEN:|// THEN:', test_code):
        quality_score += 1
        issues.append("✅ BONUS: Uses Given-When-Then structure")
    
    is_valid = quality_score >= 6  # Minimum acceptable score
    
    return is_valid, issues, quality_score

# ============================================================================
# API CALLS
# ============================================================================

def extract_dart_code(text: str) -> str:
    """Extract Dart code from response, removing markdown code blocks if present."""
    code_block_pattern = r"```(?:dart)?\s*([\s\S]*?)```"
    matches = re.findall(code_block_pattern, text)
    if matches:
        return matches[0].strip()
    return text.strip()

def call_genai(prompt: str, retry: int = 0) -> str:
    """Call Gemini API with retry logic."""
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("GOOGLE_API_KEY not set in environment.")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-exp")
    base = "https://generativelanguage.googleapis.com/v1beta/models"
    url = f"{base}/{model}:generateContent?key={api_key}"
    
    headers = {"Content-Type": "application/json"}
    
    # Temperature 0.5 = balanced (creative but consistent)
    payload = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "temperature": 0.5,  # Increased for better variety
            "maxOutputTokens": 8192,  # Increased for complex tests
            "topP": 0.9,
            "topK": 40
        }
    }
    
    print(f"[INFO] Calling Gemini API (attempt {retry + 1}/3)...")
    resp = requests.post(url, headers=headers, json=payload, timeout=180)
    
    if resp.status_code != 200:
        if retry < 2:
            print(f"[WARN] API call failed, retrying...")
            return call_genai(prompt, retry + 1)
        raise Exception(f"API failed: {resp.status_code} - {resp.text[:500]}")
    
    j = resp.json()
    if "candidates" in j and j["candidates"]:
        cand = j["candidates"][0]
        if "content" in cand and "parts" in cand["content"]:
            text = "".join(p.get("text", "") for p in cand["content"]["parts"])
            return extract_dart_code(text)
    
    raise Exception(f"Unexpected API response: {json.dumps(j)[:500]}")

# ============================================================================
# MAIN WORKFLOW
# ============================================================================

def write_test_file(src_path: str, content: str) -> str:
    """Write generated test to file."""
    rel = src_path.replace("/", "_").replace(".dart", "")
    fname = f"test_behavioral_{rel}.dart"
    out_dir = ROOT / "test" / "behavioral"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / fname
    out_path.write_text(content, encoding="utf-8")
    return str(out_path)

def main():
    print("=" * 70)
    print("🚀 QUALITY-FOCUSED Flutter Test Generator")
    print("=" * 70)
    
    modified = get_modified_dart_files()
    
    if not modified:
        print("[INFO] No modified files. Using sample files...")
        modified = get_sample_dart_files(max_files=3)
        if not modified:
            print("[WARN] No .dart files found.")
            return
    
    print(f"[INFO] Processing {len(modified)} file(s)")
    
    generated = []
    quality_report = []
    
    for f in modified:
        print(f"\n{'─' * 70}")
        print(f"📄 Processing: {f}")
        print(f"{'─' * 70}")
        
        try:
            src = read_file(f)
        except Exception as e:
            print(f"[ERROR] Could not read {f}: {e}")
            continue
        
        prompt = build_prompt(f, src)
        
        try:
            result = call_genai(prompt)
        except Exception as e:
            print(f"[ERROR] API call failed: {e}")
            continue
        
        # Validate quality
        is_valid, issues, score = validate_test_quality(result)
        
        print(f"\n📊 Quality Score: {score}/10")
        for issue in issues:
            print(f"  {issue}")
        
        if not is_valid:
            print(f"[REJECT] Quality score {score} below threshold (6). Skipping...")
            quality_report.append({
                'file': f,
                'score': score,
                'status': 'REJECTED',
                'issues': issues
            })
            continue
        
        path = write_test_file(f, result)
        generated.append(path)
        quality_report.append({
            'file': f,
            'score': score,
            'status': 'ACCEPTED',
            'test_path': path
        })
        print(f"[SUCCESS] Test generated: {path}")
    
    # Final report
    print(f"\n{'═' * 70}")
    print("📋 GENERATION REPORT")
    print(f"{'═' * 70}")
    print(f"✅ Accepted: {len(generated)}")
    print(f"❌ Rejected: {len(quality_report) - len(generated)}")
    
    if quality_report:
        avg_score = sum(r['score'] for r in quality_report) / len(quality_report)
        print(f"📊 Average Quality Score: {avg_score:.1f}/10")
    
    if generated:
        print(f"\n🔍 ACTION REQUIRED:")
        print(f"  1. Review tests in test/behavioral/")
        print(f"  2. Run: flutter test test/behavioral/")
        print(f"  3. Fix any issues before merging")
    
    print(f"{'═' * 70}\n")

if __name__ == "__main__":
    main()
