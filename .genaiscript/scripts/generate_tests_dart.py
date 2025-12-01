#!/usr/bin/env python3
"""
Generador de tests Flutter/Dart basado en LLM (Gemini via GOOGLE_API_KEY).

Usa por defecto el modelo: gemini-2.0-flash-lite

Modos de ejecución (variable GENAI_MODE):
- 'modified': Solo genera tests para archivos modificados (default)
- 'coverage': Genera tests para todos los archivos sin cobertura
- 'all': Genera tests para todos los archivos en lib/
"""
import os
import subprocess
import pathlib
import json
import requests
from typing import List, Set
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]

def run(cmd: str, check=True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\nstdout:{res.stdout}\nstderr:{res.stderr}")
    return res.stdout.strip()

def get_all_dart_files() -> List[str]:
    """Obtiene todos los archivos .dart en lib/"""
    lib_path = ROOT / "lib"
    files = []
    for f in lib_path.rglob("*.dart"):
        rel_path = str(f.relative_to(ROOT))
        files.append(rel_path)
    return files

def get_existing_test_files() -> Set[str]:
    """Obtiene todos los archivos de test existentes"""
    test_path = ROOT / "test"
    test_files = set()
    if test_path.exists():
        for f in test_path.rglob("*.dart"):
            test_files.add(str(f.relative_to(ROOT)))
    return test_files

def get_files_without_tests(all_files: List[str], existing_tests: Set[str]) -> List[str]:
    """Filtra archivos que no tienen tests correspondientes"""
    files_without_tests = []
    for f in all_files:
        # Generar posibles nombres de test
        base_name = pathlib.Path(f).stem
        has_test = False
        for test_file in existing_tests:
            if base_name in test_file or f"test_{base_name}" in test_file:
                has_test = True
                break
        if not has_test:
            files_without_tests.append(f)
    return files_without_tests

def get_modified_dart_files() -> List[str]:
    """Obtiene archivos modificados comparando con origin/main"""
    try:
        run("git fetch origin main --depth=1", check=False)
    except Exception:
        pass
    out = run("git diff --name-only origin/main...HEAD", check=False)
    files = [f.strip() for f in out.splitlines() if f.strip().endswith(".dart")]
    files = [f for f in files if not f.startswith("test/")]
    files = [f for f in files if f.startswith("lib/")]
    return files

def get_target_files() -> List[str]:
    """Obtiene la lista de archivos objetivo según el modo de ejecución"""
    mode = os.getenv("GENAI_MODE", "modified").lower()
    max_files = int(os.getenv("GENAI_MAX_FILES", "10"))
    
    print(f"[INFO] Modo de ejecución: {mode}")
    
    if mode == "all":
        files = get_all_dart_files()
    elif mode == "coverage":
        all_files = get_all_dart_files()
        existing_tests = get_existing_test_files()
        files = get_files_without_tests(all_files, existing_tests)
        print(f"[INFO] Archivos sin cobertura: {len(files)}")
    else:  # modified (default)
        files = get_modified_dart_files()
    
    # Limitar cantidad de archivos para no sobrecargar la API
    if len(files) > max_files:
        print(f"[INFO] Limitando a {max_files} archivos (de {len(files)} encontrados)")
        files = files[:max_files]
    
    return files

def read_file(path: str) -> str:
    p = ROOT / path
    return p.read_text(encoding="utf-8")

def build_prompt(file_path: str, source: str) -> str:
    prompt = f"""
Eres un experto en Flutter/Dart y en escribir pruebas de alta calidad.
Objetivo: generar pruebas enfocadas en comportamiento real de usuario (no cantidad),
usando flutter_test y mocks cuando sea necesario.

Archivo objetivo: {file_path}
Contexto: aplica patrón de tests unitarios y widget tests cuando proceda.
Prioriza:
- Escenarios reales de usuario (inputs, estados, errores manejados).
- Tests legibles, con nombre claro y asserts significativos.
- Usar `widgetTester` para interacciones UI cuando aplique.
- Mockear servicios externos y dependencias (ej: repositorios, http).
- No incluyas explicaciones, devuelve SOLO el contenido del archivo de test.

Código fuente:
{source}

Devuelve el contenido completo del archivo de prueba.
"""
    return prompt

def call_genai(prompt: str) -> str:
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        raise Exception("GOOGLE_API_KEY no definida en el entorno.")
    model = os.getenv("GENAI_MODEL", "gemini-2.0-flash-lite")
    custom_url = os.getenv("GENAI_API_URL")
    if custom_url:
        url = custom_url
    else:
        base = "https://generativelanguage.googleapis.com/v1beta2/models"
        url = f"{base}/{model}:generate?key={api_key}"
    headers = {"Content-Type": "application/json"}
    payload = {
        "prompt": {"text": prompt},
        "temperature": float(os.getenv("GENAI_TEMPERATURE", "0.0")),
        "max_output_tokens": int(os.getenv("GENAI_MAX_TOKENS", "1200"))
    }
    resp = requests.post(url, headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    j = resp.json()
    # Extraer texto generado (candidates/content)
    if "candidates" in j and isinstance(j["candidates"], list) and j["candidates"]:
        cand = j["candidates"][0]
        if isinstance(cand, dict):
            return cand.get("content") or cand.get("output") or json.dumps(cand, ensure_ascii=False)
    # Fallback: devolver representación JSON
    return json.dumps(j, ensure_ascii=False)

def write_test_file(src_path: str, content: str) -> str:
    rel = src_path.replace("/", "_").replace(".dart", "")
    fname = f"test_behavioral_{rel}.dart"
    out_dir = ROOT / "test" / "behavioral"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / fname
    out_path.write_text(content, encoding="utf-8")
    print(f"[INFO] Test generado: {out_path}")
    return str(out_path)

def validate_test_syntax(test_path: str) -> bool:
    """Valida que el archivo de test tenga sintaxis válida de Dart"""
    try:
        result = run(f"dart analyze {test_path}", check=False)
        return "error" not in result.lower()
    except Exception:
        return False

def run_single_test(test_path: str) -> tuple:
    """Ejecuta un test específico y retorna (success, output)"""
    try:
        result = run(f"flutter test {test_path}", check=False)
        success = "All tests passed" in result or "tests passed" in result.lower()
        return (success, result)
    except Exception as e:
        return (False, str(e))

def clean_generated_content(content: str) -> str:
    """Limpia el contenido generado, removiendo markdown code blocks"""
    # Remover bloques de código markdown
    content = re.sub(r'^```dart\s*\n?', '', content)
    content = re.sub(r'^```\s*\n?', '', content)
    content = re.sub(r'\n```\s*$', '', content)
    return content.strip()

def main():
    print("[START] Generador de tests Flutter/Dart con GenAI")
    print(f"[INFO] Modelo: {os.getenv('GENAI_MODEL', 'gemini-2.0-flash-lite')}")
    
    target_files = get_target_files()
    if not target_files:
        mode = os.getenv("GENAI_MODE", "modified")
        if mode == "modified":
            print("[INFO] No hay archivos .dart modificados en lib/ respecto a origin/main.")
        else:
            print(f"[INFO] No hay archivos objetivo para el modo '{mode}'.")
        return
    
    print(f"[INFO] Archivos objetivo: {len(target_files)}")
    for f in target_files:
        print(f"  - {f}")
    
    generated = []
    failed = []
    validated = []
    
    for f in target_files:
        try:
            src = read_file(f)
        except Exception as e:
            print(f"[WARN] No se pudo leer {f}: {e}")
            continue
        
        prompt = build_prompt(f, src)
        try:
            result = call_genai(prompt)
            result = clean_generated_content(result)
        except Exception as e:
            print(f"[ERROR] Llamada GenAI falló para {f}: {e}")
            failed.append((f, str(e)))
            continue
        
        path = write_test_file(f, result)
        generated.append(path)
        
        # Validar sintaxis si está habilitado
        if os.getenv("GENAI_VALIDATE_SYNTAX", "false").lower() == "true":
            if validate_test_syntax(path):
                validated.append(path)
                print(f"[OK] Sintaxis válida: {path}")
            else:
                print(f"[WARN] Sintaxis inválida: {path}")
    
    # Resumen
    print("\n" + "="*60)
    print("[RESUMEN] Generación de tests completada")
    print(f"  - Archivos procesados: {len(target_files)}")
    print(f"  - Tests generados: {len(generated)}")
    print(f"  - Fallos de generación: {len(failed)}")
    if validated:
        print(f"  - Tests con sintaxis válida: {len(validated)}")
    print("="*60)
    
    if not generated:
        print("[INFO] No se generaron tests.")
    else:
        print("[INFO] Tests generados:")
        for p in generated:
            print(f"  - {p}")
        
        if os.getenv("REQUIRE_HUMAN_REVIEW", "true").lower() == "true":
            print("\n[ACTION] Requiere revisión humana: revisa los archivos en test/behavioral/ y valida antes de mergear.")
        else:
            print("\n[ACTION] REQUIRE_HUMAN_REVIEW=false -> podrías activar commit/PR automático en el workflow.")

if __name__ == "__main__":
    main()
