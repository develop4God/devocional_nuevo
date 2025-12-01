#!/usr/bin/env python3
"""
Análisis de calidad de código con GenAI.

Tipos de análisis (variable ANALYSIS_TYPE):
- 'lint': Análisis de linting y estilo
- 'complexity': Análisis de complejidad
- 'duplicates': Detección de código duplicado
- 'all': Todos los análisis
"""
import os
import subprocess
import pathlib
import json
import requests
from typing import List, Dict
from collections import defaultdict
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]

def run(cmd: str, check=True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=str(ROOT))
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}")
    return res.stdout.strip()

def read_file(path: str) -> str:
    p = ROOT / path if not pathlib.Path(path).is_absolute() else pathlib.Path(path)
    if p.exists():
        return p.read_text(encoding="utf-8")
    return ""

def get_all_dart_files() -> List[str]:
    """Obtiene todos los archivos .dart en lib/"""
    lib_path = ROOT / "lib"
    files = []
    for f in lib_path.rglob("*.dart"):
        rel_path = str(f.relative_to(ROOT))
        files.append(rel_path)
    return files

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
        "temperature": float(os.getenv("GENAI_TEMPERATURE", "0.2")),
        "max_output_tokens": int(os.getenv("GENAI_MAX_TOKENS", "2000"))
    }
    resp = requests.post(url, headers=headers, json=payload, timeout=120)
    resp.raise_for_status()
    j = resp.json()
    if "candidates" in j and isinstance(j["candidates"], list) and j["candidates"]:
        cand = j["candidates"][0]
        if isinstance(cand, dict):
            return cand.get("content") or cand.get("output") or ""
    return ""

def analyze_complexity(files: List[str]) -> Dict:
    """Analiza la complejidad de los archivos"""
    stats = {
        "total_files": len(files),
        "total_lines": 0,
        "large_files": [],
        "complex_files": []
    }
    
    for f in files:
        content = read_file(f)
        lines = len(content.splitlines())
        stats["total_lines"] += lines
        
        if lines > 500:
            stats["large_files"].append({"file": f, "lines": lines})
        
        # Detectar complejidad (clases, métodos, condicionales anidados)
        classes = len(re.findall(r'\bclass\s+\w+', content))
        methods = len(re.findall(r'\b(?:void|Future|Stream|String|int|double|bool|List|Map|Set|dynamic)\s+\w+\s*\(', content))
        nested_ifs = len(re.findall(r'if\s*\([^)]+\)\s*\{[^}]*if\s*\(', content))
        
        if classes > 5 or methods > 20 or nested_ifs > 3:
            stats["complex_files"].append({
                "file": f,
                "classes": classes,
                "methods": methods,
                "nested_conditionals": nested_ifs
            })
    
    return stats

def detect_duplicates(files: List[str]) -> List[Dict]:
    """Detecta posibles duplicados de código"""
    code_blocks = defaultdict(list)
    duplicates = []
    
    for f in files:
        content = read_file(f)
        # Extraer bloques de código significativos (funciones/métodos)
        methods = re.findall(r'((?:void|Future|Stream|String|int|double|bool|List|Map|Set|dynamic)\s+\w+\s*\([^)]*\)\s*(?:async\s*)?\{[^}]{50,500}\})', content)
        
        for method in methods:
            # Normalizar el código para comparación
            normalized = re.sub(r'\s+', ' ', method.strip())
            code_blocks[normalized[:200]].append(f)
    
    for code, files_list in code_blocks.items():
        if len(files_list) > 1:
            duplicates.append({
                "code_preview": code[:100] + "...",
                "files": files_list
            })
    
    return duplicates[:10]  # Limitar a 10 duplicados

def analyze_lint_issues() -> str:
    """Obtiene los problemas de linting"""
    try:
        output = run("dart analyze lib/ 2>&1", check=False)
        return output[:3000]
    except Exception:
        return "No se pudo ejecutar dart analyze"

def main():
    analysis_type = os.getenv("ANALYSIS_TYPE", "all").lower()
    files = get_all_dart_files()
    
    print("## 📊 Análisis de Calidad de Código")
    print()
    print(f"**Archivos analizados:** {len(files)}")
    print()
    
    if analysis_type in ["all", "lint"]:
        print("### 🔍 Análisis de Linting")
        print()
        lint_output = analyze_lint_issues()
        if "No issues found" in lint_output or not lint_output.strip():
            print("✅ No se encontraron problemas de linting.")
        else:
            print("```")
            print(lint_output)
            print("```")
        print()
    
    if analysis_type in ["all", "complexity"]:
        print("### 📈 Análisis de Complejidad")
        print()
        complexity = analyze_complexity(files)
        print(f"- **Total de archivos:** {complexity['total_files']}")
        print(f"- **Total de líneas:** {complexity['total_lines']}")
        print()
        
        if complexity["large_files"]:
            print("#### Archivos grandes (>500 líneas)")
            for f in complexity["large_files"][:5]:
                print(f"- `{f['file']}`: {f['lines']} líneas")
            print()
        
        if complexity["complex_files"]:
            print("#### Archivos complejos")
            for f in complexity["complex_files"][:5]:
                print(f"- `{f['file']}`: {f['classes']} clases, {f['methods']} métodos, {f['nested_conditionals']} condicionales anidados")
            print()
    
    if analysis_type in ["all", "duplicates"]:
        print("### 🔄 Detección de Código Duplicado")
        print()
        duplicates = detect_duplicates(files)
        if duplicates:
            print(f"Se encontraron {len(duplicates)} posibles duplicados:")
            print()
            for i, dup in enumerate(duplicates[:5], 1):
                print(f"**Duplicado {i}:**")
                print(f"- Archivos: {', '.join(dup['files'])}")
                print(f"- Preview: `{dup['code_preview']}`")
                print()
        else:
            print("✅ No se detectaron duplicados significativos.")
        print()
    
    # Análisis GenAI adicional
    print("### 🤖 Análisis Inteligente (GenAI)")
    print()
    
    # Seleccionar archivos para análisis profundo
    sample_files = files[:5]
    sample_content = ""
    for f in sample_files:
        content = read_file(f)
        sample_content += f"\n--- {f} ---\n{content[:800]}\n"
    
    prompt = f"""
Eres un experto en calidad de código Flutter/Dart.
Analiza estos archivos y proporciona recomendaciones de mejora.

Archivos:
{sample_content}

Proporciona un análisis breve en Markdown con:
1. Problemas de calidad detectados
2. Mejoras de legibilidad sugeridas
3. Buenas prácticas que deberían aplicarse
4. Puntuación general de calidad (1-10)

Sé conciso y práctico.
"""
    
    try:
        result = call_genai(prompt)
        print(result)
    except Exception as e:
        print(f"⚠️ No se pudo realizar el análisis GenAI: {e}")
    
    print()
    print("---")
    print("_Análisis generado automáticamente_")

if __name__ == "__main__":
    main()
