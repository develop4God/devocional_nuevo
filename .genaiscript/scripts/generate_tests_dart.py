#!/usr/bin/env python3
"""
Generador de tests Flutter/Dart basado en LLM (Gemini via GOOGLE_API_KEY).

Usa por defecto el modelo: gemini-2.0-flash-lite
"""
import os
import subprocess
import pathlib
import json
import requests
from typing import List

ROOT = pathlib.Path(__file__).resolve().parents[2]

def run(cmd: str, check=True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\nstdout:{res.stdout}\nstderr:{res.stderr}")
    return res.stdout.strip()

def get_modified_dart_files() -> List[str]:
    try:
        run("git fetch origin main --depth=1", check=False)
    except Exception:
        pass
    out = run("git diff --name-only origin/main...HEAD", check=False)
    files = [f.strip() for f in out.splitlines() if f.strip().endswith(".dart")]
    files = [f for f in files if not f.startswith("test/")]
    files = [f for f in files if f.startswith("lib/")]
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

def main():
    print("[START] Generador de tests Flutter/Dart con GenAI (gemini-2.0-flash-lite)")
    modified = get_modified_dart_files()
    if not modified:
        print("[INFO] No hay archivos .dart modificados en lib/ respecto a origin/main.")
        return
    generated = []
    for f in modified:
        try:
            src = read_file(f)
        except Exception as e:
            print(f"[WARN] No se pudo leer {f}: {e}")
            continue
        prompt = build_prompt(f, src)
        try:
            result = call_genai(prompt)
        except Exception as e:
            print(f"[ERROR] Llamada GenAI falló para {f}: {e}")
            continue
        path = write_test_file(f, result)
        generated.append(path)
    if not generated:
        print("[INFO] No se generaron tests.")
    else:
        print("[INFO] Tests generados:", generated)
        if os.getenv("REQUIRE_HUMAN_REVIEW", "true").lower() == "true":
            print("[ACTION] Requiere revisión humana: revisa los archivos en test/behavioral/ y valida antes de mergear.")
        else:
            print("[ACTION] REQUIRE_HUMAN_REVIEW=false -> podrías activar commit/PR automático en el workflow.")

if __name__ == "__main__":
    main()
