#!/usr/bin/env python3
"""
Revisión arquitectónica automatizada con GenAI.

Tipos de revisión (variable REVIEW_TYPE):
- 'full': Revisión completa de arquitectura
- 'security': Análisis de seguridad
- 'performance': Análisis de rendimiento
- 'patterns': Revisión de patrones de diseño
"""
import os
import subprocess
import pathlib
import json
import requests
from typing import List, Dict
from datetime import datetime

ROOT = pathlib.Path(__file__).resolve().parents[2]

def run(cmd: str, check=True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}")
    return res.stdout.strip()

def read_file(path: str) -> str:
    p = ROOT / path if not pathlib.Path(path).is_absolute() else pathlib.Path(path)
    if p.exists():
        return p.read_text(encoding="utf-8")
    return ""

def get_project_structure() -> str:
    """Obtiene la estructura del proyecto"""
    structure = []
    lib_path = ROOT / "lib"
    for f in lib_path.rglob("*.dart"):
        rel_path = str(f.relative_to(ROOT))
        structure.append(rel_path)
    return "\n".join(structure[:80])

def get_dependencies() -> str:
    """Lee las dependencias del pubspec.yaml"""
    pubspec = read_file("pubspec.yaml")
    return pubspec[:2000] if pubspec else "No pubspec.yaml encontrado"

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
        "temperature": float(os.getenv("GENAI_TEMPERATURE", "0.3")),
        "max_output_tokens": int(os.getenv("GENAI_MAX_TOKENS", "2500"))
    }
    resp = requests.post(url, headers=headers, json=payload, timeout=180)
    resp.raise_for_status()
    j = resp.json()
    if "candidates" in j and isinstance(j["candidates"], list) and j["candidates"]:
        cand = j["candidates"][0]
        if isinstance(cand, dict):
            return cand.get("content") or cand.get("output") or ""
    return ""

def review_full() -> str:
    """Revisión arquitectónica completa"""
    structure = get_project_structure()
    deps = get_dependencies()
    
    # Leer archivos clave
    main_content = read_file("lib/main.dart")[:1500]
    
    prompt = f"""
Eres un arquitecto de software senior especializado en Flutter/Dart.
Realiza una revisión arquitectónica completa del proyecto.

Estructura del proyecto:
{structure}

Dependencias (pubspec.yaml):
{deps}

Archivo main.dart:
{main_content}

Genera un reporte de revisión arquitectónica en Markdown que incluya:

## 📊 Resumen Ejecutivo
(Breve resumen del estado del proyecto)

## ✅ Fortalezas
(Lista de puntos positivos de la arquitectura)

## ⚠️ Áreas de Mejora
(Lista de aspectos que podrían mejorarse)

## 🔴 Problemas Críticos
(Si existen problemas que requieren atención inmediata)

## 📝 Recomendaciones
(Sugerencias específicas de mejora con prioridad)

## 📈 Próximos Pasos
(Acciones recomendadas en orden de prioridad)

Sé específico y práctico en las recomendaciones.
"""
    return call_genai(prompt)

def review_security() -> str:
    """Análisis de seguridad"""
    structure = get_project_structure()
    deps = get_dependencies()
    
    # Buscar archivos relacionados con seguridad
    security_files = []
    for pattern in ["auth", "login", "token", "crypto", "secure", "password"]:
        for f in (ROOT / "lib").rglob(f"*{pattern}*.dart"):
            content = f.read_text(encoding="utf-8")[:1000]
            security_files.append(f"--- {f.name} ---\n{content}")
    
    security_content = "\n\n".join(security_files[:5]) if security_files else "No se encontraron archivos de seguridad específicos"
    
    prompt = f"""
Eres un experto en seguridad de aplicaciones móviles Flutter.
Realiza un análisis de seguridad del proyecto.

Estructura del proyecto:
{structure}

Dependencias:
{deps}

Archivos relacionados con seguridad:
{security_content}

Genera un reporte de seguridad en Markdown:

## 🔒 Análisis de Seguridad

### Estado General
(Evaluación general de la postura de seguridad)

### 🔴 Vulnerabilidades Potenciales
(Lista de posibles problemas de seguridad)

### ⚠️ Advertencias
(Prácticas que podrían mejorarse)

### ✅ Buenas Prácticas Detectadas
(Aspectos positivos de seguridad)

### 📝 Recomendaciones de Seguridad
(Acciones específicas para mejorar la seguridad)

Sé específico sobre los riesgos y cómo mitigarlos.
"""
    return call_genai(prompt)

def review_performance() -> str:
    """Análisis de rendimiento"""
    structure = get_project_structure()
    
    # Buscar widgets y páginas
    widgets_count = len(list((ROOT / "lib").rglob("*widget*.dart")))
    pages_count = len(list((ROOT / "lib").rglob("*page*.dart")))
    blocs_count = len(list((ROOT / "lib").rglob("*bloc*.dart")))
    
    # Leer algunos widgets para análisis
    sample_widgets = []
    for f in list((ROOT / "lib").rglob("*widget*.dart"))[:3]:
        content = f.read_text(encoding="utf-8")[:1500]
        sample_widgets.append(f"--- {f.name} ---\n{content}")
    
    prompt = f"""
Eres un experto en optimización de rendimiento de aplicaciones Flutter.
Analiza el proyecto para identificar oportunidades de mejora de rendimiento.

Estadísticas del proyecto:
- Widgets: {widgets_count}
- Páginas: {pages_count}
- BLoCs: {blocs_count}

Estructura:
{structure}

Muestra de widgets:
{chr(10).join(sample_widgets[:2]) if sample_widgets else "No se encontraron widgets"}

Genera un reporte de rendimiento en Markdown:

## ⚡ Análisis de Rendimiento

### Métricas del Proyecto
(Resumen de la complejidad del proyecto)

### 🔴 Problemas de Rendimiento
(Posibles cuellos de botella o ineficiencias)

### ⚠️ Áreas de Atención
(Aspectos que podrían afectar el rendimiento)

### ✅ Buenas Prácticas
(Aspectos positivos para el rendimiento)

### 📝 Optimizaciones Recomendadas
(Acciones específicas para mejorar rendimiento)

Incluye ejemplos de código cuando sea posible.
"""
    return call_genai(prompt)

def review_patterns() -> str:
    """Revisión de patrones de diseño"""
    structure = get_project_structure()
    
    # Detectar patrones usados
    patterns_detected = []
    if (ROOT / "lib" / "blocs").exists():
        patterns_detected.append("BLoC Pattern")
    if (ROOT / "lib" / "providers").exists():
        patterns_detected.append("Provider Pattern")
    if (ROOT / "lib" / "services").exists():
        patterns_detected.append("Service Layer")
    if (ROOT / "lib" / "models").exists():
        patterns_detected.append("Model Layer")
    if (ROOT / "lib" / "controllers").exists():
        patterns_detected.append("Controller Pattern")
    
    # Leer ejemplos de cada patrón
    samples = []
    for folder in ["blocs", "services", "controllers", "providers"]:
        folder_path = ROOT / "lib" / folder
        if folder_path.exists():
            for f in list(folder_path.glob("*.dart"))[:2]:
                content = f.read_text(encoding="utf-8")[:1200]
                samples.append(f"--- {folder}/{f.name} ---\n{content}")
    
    prompt = f"""
Eres un experto en patrones de diseño y arquitectura de software Flutter.
Analiza los patrones de diseño utilizados en el proyecto.

Patrones detectados:
{', '.join(patterns_detected) if patterns_detected else 'No se detectaron patrones específicos'}

Estructura del proyecto:
{structure}

Muestras de código:
{chr(10).join(samples[:4]) if samples else "No se encontraron muestras"}

Genera un reporte de patrones en Markdown:

## 🎨 Revisión de Patrones de Diseño

### Patrones Identificados
(Lista de patrones detectados y su uso)

### ✅ Implementación Correcta
(Patrones bien implementados)

### ⚠️ Implementación a Mejorar
(Patrones que podrían mejorarse)

### 🔴 Anti-patrones Detectados
(Si existen prácticas que deberían evitarse)

### 📝 Recomendaciones
(Sugerencias para mejorar la arquitectura)

### 📚 Patrones Sugeridos
(Patrones que podrían beneficiar al proyecto)

Incluye ejemplos específicos del código analizado.
"""
    return call_genai(prompt)

def main():
    print(f"# 🏗️ Revisión Arquitectónica")
    print(f"**Fecha:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"**Repositorio:** {ROOT.name}")
    print()
    
    review_type = os.getenv("REVIEW_TYPE", "full").lower()
    print(f"**Tipo de revisión:** {review_type}")
    print()
    print("---")
    print()
    
    try:
        if review_type == "full":
            result = review_full()
        elif review_type == "security":
            result = review_security()
        elif review_type == "performance":
            result = review_performance()
        elif review_type == "patterns":
            result = review_patterns()
        else:
            result = review_full()  # Default to full
        
        print(result)
    except Exception as e:
        print(f"\n⚠️ Error durante la revisión: {e}")
    
    print()
    print("---")
    print("_Revisión generada automáticamente por GenAI_")

if __name__ == "__main__":
    main()
