#!/usr/bin/env python3
"""
Análisis de dependencias con GenAI.
Analiza pubspec.yaml y genera recomendaciones.
"""
import os
import subprocess
import pathlib
import json
import requests
from typing import Dict, List
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]

def read_file(path: str) -> str:
    p = ROOT / path if not pathlib.Path(path).is_absolute() else pathlib.Path(path)
    if p.exists():
        return p.read_text(encoding="utf-8")
    return ""

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

def parse_pubspec() -> Dict:
    """Parsea pubspec.yaml y extrae dependencias"""
    pubspec = read_file("pubspec.yaml")
    
    # Extraer dependencias
    deps_section = re.search(r'dependencies:\s*\n((?:\s+[^\n]+\n)+)', pubspec)
    dev_deps_section = re.search(r'dev_dependencies:\s*\n((?:\s+[^\n]+\n)+)', pubspec)
    
    deps = []
    dev_deps = []
    
    if deps_section:
        for line in deps_section.group(1).splitlines():
            match = re.match(r'\s+(\w+):\s*(.+)', line)
            if match:
                deps.append({"name": match.group(1), "version": match.group(2).strip()})
    
    if dev_deps_section:
        for line in dev_deps_section.group(1).splitlines():
            match = re.match(r'\s+(\w+):\s*(.+)', line)
            if match:
                dev_deps.append({"name": match.group(1), "version": match.group(2).strip()})
    
    return {
        "dependencies": deps,
        "dev_dependencies": dev_deps,
        "raw": pubspec
    }

def get_outdated_info() -> str:
    """Lee información de paquetes desactualizados"""
    outdated_file = ROOT / "dependency_reports" / "outdated.txt"
    if outdated_file.exists():
        return outdated_file.read_text(encoding="utf-8")
    return ""

def main():
    print("## 📦 Análisis de Dependencias")
    print()
    
    pubspec_info = parse_pubspec()
    outdated_info = get_outdated_info()
    
    print(f"**Dependencias principales:** {len(pubspec_info['dependencies'])}")
    print(f"**Dependencias de desarrollo:** {len(pubspec_info['dev_dependencies'])}")
    print()
    
    # Listar dependencias
    print("### Lista de Dependencias")
    print()
    print("#### Producción")
    for dep in pubspec_info["dependencies"][:20]:
        print(f"- `{dep['name']}`: {dep['version']}")
    print()
    
    print("#### Desarrollo")
    for dep in pubspec_info["dev_dependencies"][:10]:
        print(f"- `{dep['name']}`: {dep['version']}")
    print()
    
    # Análisis GenAI
    print("### 🤖 Análisis Inteligente")
    print()
    
    prompt = f"""
Eres un experto en Flutter/Dart y gestión de dependencias.
Analiza las dependencias de este proyecto y proporciona recomendaciones.

pubspec.yaml:
{pubspec_info['raw'][:3000]}

Información de paquetes desactualizados:
{outdated_info[:2000] if outdated_info else 'No disponible'}

Proporciona un análisis en Markdown que incluya:

#### Evaluación General
(Estado general de las dependencias)

#### 🔴 Dependencias Críticas a Actualizar
(Paquetes que requieren actualización urgente por seguridad o compatibilidad)

#### ⚠️ Dependencias Desactualizadas
(Paquetes que tienen versiones más recientes disponibles)

#### ✅ Dependencias en Buen Estado
(Paquetes que están actualizados)

#### 📝 Recomendaciones
(Sugerencias específicas para mejorar la gestión de dependencias)

#### 🔒 Consideraciones de Seguridad
(Si hay paquetes conocidos con vulnerabilidades)

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
