#!/usr/bin/env python3
"""
Flutter/Dart test generator using LLM (Gemini via GOOGLE_API_KEY).

Default model: gemini-2.0-flash-lite
"""
import os
import subprocess
import pathlib
import json
import re
import requests
from typing import List, Optional

ROOT = pathlib.Path(__file__).resolve().parents[2]


def run(cmd: str, check: bool = True) -> str:
    """Run a shell command and return stdout."""
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


def get_sample_dart_files(max_files: int = 3) -> List[str]:
    """Get sample .dart files from lib/ when no modified files are found."""
    lib_path = ROOT / "lib"
    dart_files = []
    
    # Priority folders for sample tests
    priority_folders = ["services", "blocs", "utils", "widgets", "models"]
    
    for folder in priority_folders:
        folder_path = lib_path / folder
        if folder_path.exists():
            for dart_file in folder_path.glob("*.dart"):
                rel_path = str(dart_file.relative_to(ROOT))
                dart_files.append(rel_path)
                if len(dart_files) >= max_files:
                    return dart_files
    
    # If still need more files, search recursively
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


def build_prompt(file_path: str, source: str) -> str:
    """Build the prompt for test generation."""
    prompt = f"""You are an expert Flutter/Dart developer skilled at writing high-quality tests.

OBJECTIVE: Generate behavioral tests focused on real user scenarios (quality over quantity), using flutter_test and mocks when necessary.

TARGET FILE: {file_path}

CONTEXT: Apply unit test and widget test patterns as appropriate.

REQUIREMENTS:
- Focus on real user scenarios (inputs, states, error handling)
- Write readable tests with clear names and meaningful assertions
- Use `WidgetTester` for UI interactions when applicable
- Mock external services and dependencies (e.g., repositories, HTTP clients)
- Follow Flutter testing best practices
- Include proper imports at the top of the file
- Use `group()` to organize related tests
- Use descriptive test names that explain the expected behavior

IMPORTANT:
- Return ONLY the complete Dart test file content
- Do NOT include any explanations, markdown formatting, or code blocks
- The output should start with import statements and be valid Dart code
- Do NOT wrap the code in ```dart``` or any other markers

SOURCE CODE:
{source}

Generate the complete test file now:"""
    return prompt


def extract_dart_code(text: str) -> str:
    """Extract Dart code from response, removing markdown code blocks if present."""
    # Remove markdown code blocks if present
    code_block_pattern = r"```(?:dart)?\s*([\s\S]*?)```"
    matches = re.findall(code_block_pattern, text)
    if matches:
        return matches[0].strip()
    
    # If no code blocks, return the text as-is (cleaned up)
    return text.strip()


def call_genai(prompt: str) -> str:
    """Call Gemini API and return the generated text."""
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("GOOGLE_API_KEY not set in environment.")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-lite")
    custom_url = os.getenv("GENAI_API_URL")
    
    if custom_url:
        url = custom_url
    else:
        # Use the correct v1beta API endpoint with generateContent
        base = "https://generativelanguage.googleapis.com/v1beta/models"
        url = f"{base}/{model}:generateContent?key={api_key}"
    
    headers = {"Content-Type": "application/json"}
    
    # Use the correct request format for Gemini API v1beta
    # Temperature 0.2 provides slight creativity while maintaining code quality
    # (0.0 was too deterministic, higher values produce inconsistent code)
    payload = {
        "contents": [
            {
                "parts": [
                    {"text": prompt}
                ]
            }
        ],
        "generationConfig": {
            "temperature": float(os.getenv("GENAI_TEMPERATURE", "0.2")),
            "maxOutputTokens": int(os.getenv("GENAI_MAX_TOKENS", "4096")),
            "topP": 0.95,
            "topK": 40
        }
    }
    
    print(f"[INFO] Calling Gemini API with model: {model}")
    resp = requests.post(url, headers=headers, json=payload, timeout=180)
    
    if resp.status_code != 200:
        error_detail = resp.text[:500] if resp.text else "No error details"
        raise Exception(
            f"API request failed with status {resp.status_code}: {error_detail}"
        )
    
    j = resp.json()
    
    # Extract text from the new API response format
    # Response format: {"candidates": [{"content": {"parts": [{"text": "..."}]}}]}
    if "candidates" in j and isinstance(j["candidates"], list) and j["candidates"]:
        cand = j["candidates"][0]
        if isinstance(cand, dict) and "content" in cand:
            content = cand["content"]
            if isinstance(content, dict) and "parts" in content:
                parts = content["parts"]
                if isinstance(parts, list) and parts:
                    text_parts = [p.get("text", "") for p in parts if isinstance(p, dict)]
                    generated_text = "".join(text_parts)
                    # Extract Dart code (remove markdown if present)
                    return extract_dart_code(generated_text)
    
    # Fallback: return JSON representation for debugging
    print(f"[WARN] Unexpected API response format: {json.dumps(j, indent=2)[:500]}")
    return json.dumps(j, ensure_ascii=False)


def write_test_file(src_path: str, content: str) -> str:
    """Write generated test to file."""
    rel = src_path.replace("/", "_").replace(".dart", "")
    fname = f"test_behavioral_{rel}.dart"
    out_dir = ROOT / "test" / "behavioral"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / fname
    out_path.write_text(content, encoding="utf-8")
    print(f"[INFO] Test generated: {out_path}")
    return str(out_path)


def main():
    print("[START] Flutter/Dart Test Generator with GenAI")
    
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-lite")
    print(f"[INFO] Using model: {model}")
    
    modified = get_modified_dart_files()
    
    if not modified:
        print("[INFO] No modified .dart files found in lib/ compared to origin/main.")
        print("[INFO] Generating sample tests from existing source files...")
        modified = get_sample_dart_files(max_files=3)
        if not modified:
            print("[WARN] No .dart files found in lib/ to generate tests from.")
            return
        print(f"[INFO] Selected sample files: {modified}")
    else:
        print(f"[INFO] Found {len(modified)} modified file(s): {modified}")
    
    generated = []
    for f in modified:
        print(f"[INFO] Processing: {f}")
        try:
            src = read_file(f)
        except Exception as e:
            print(f"[WARN] Could not read {f}: {e}")
            continue
        
        prompt = build_prompt(f, src)
        
        try:
            result = call_genai(prompt)
        except Exception as e:
            print(f"[ERROR] GenAI call failed for {f}: {e}")
            continue
        
        # Validate that we got actual Dart code (check for common patterns)
        is_likely_dart = (
            result.strip().startswith("import") or
            result.strip().startswith("//") or
            result.strip().startswith("library") or
            result.strip().startswith("part") or
            "void main(" in result or
            "test(" in result or
            "group(" in result
        )
        if not is_likely_dart:
            print(f"[WARN] Generated content for {f} doesn't look like valid Dart code")
            print(f"[DEBUG] First 200 chars: {result[:200]}")
        
        path = write_test_file(f, result)
        generated.append(path)
    
    if not generated:
        print("[INFO] No tests were generated.")
    else:
        print(f"[INFO] Tests generated: {generated}")
        if os.getenv("REQUIRE_HUMAN_REVIEW", "true").lower() == "true":
            print(
                "[ACTION] Human review required: review files in test/behavioral/ "
                "and validate before merging."
            )
        else:
            print(
                "[ACTION] REQUIRE_HUMAN_REVIEW=false -> automatic commit/PR "
                "can be enabled in the workflow."
            )


if __name__ == "__main__":
    main()
