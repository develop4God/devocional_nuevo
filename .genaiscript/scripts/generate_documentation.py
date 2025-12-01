#!/usr/bin/env python3
"""
Generador de documentación Flutter/Dart basado en LLM (Gemini).

Modos de ejecución (variable DOC_SCOPE):
- 'readme': Actualiza el README.md principal
- 'api': Genera documentación de API para archivos públicos
- 'architecture': Genera/actualiza documentación de arquitectura
- 'all': Ejecuta todos los modos
"""
import os
import subprocess
import pathlib
import json
import requests
from typing import List, Dict

ROOT = pathlib.Path(__file__).resolve().parents[2]

def run(cmd: str, check=True) -> str:
    res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if check and res.returncode != 0:
        raise Exception(f"Command failed: {cmd}\nstdout:{res.stdout}\nstderr:{res.stderr}")
    return res.stdout.strip()

def read_file(path: str) -> str:
    p = ROOT / path if not pathlib.Path(path).is_absolute() else pathlib.Path(path)
    if p.exists():
        return p.read_text(encoding="utf-8")
    return ""

def write_file(path: str, content: str) -> None:
    p = ROOT / path if not pathlib.Path(path).is_absolute() else pathlib.Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    print(f"[INFO] Archivo escrito: {p}")

def get_project_structure() -> str:
    """Obtiene la estructura del proyecto"""
    structure = []
    lib_path = ROOT / "lib"
    for f in lib_path.rglob("*.dart"):
        rel_path = str(f.relative_to(ROOT))
        structure.append(rel_path)
    return "\n".join(structure[:100])  # Limitar para no sobrecargar el prompt

def get_pubspec_info() -> Dict:
    """Lee información del pubspec.yaml"""
    pubspec_path = ROOT / "pubspec.yaml"
    if pubspec_path.exists():
        import re
        content = pubspec_path.read_text()
        name_match = re.search(r'^name:\s*(.+)$', content, re.MULTILINE)
        desc_match = re.search(r'^description:\s*(.+)$', content, re.MULTILINE)
        version_match = re.search(r'^version:\s*(.+)$', content, re.MULTILINE)
        return {
            "name": name_match.group(1).strip() if name_match else "Unknown",
            "description": desc_match.group(1).strip() if desc_match else "",
            "version": version_match.group(1).strip() if version_match else "0.0.0"
        }
    return {"name": "Unknown", "description": "", "version": "0.0.0"}

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
            return cand.get("content") or cand.get("output") or json.dumps(cand, ensure_ascii=False)
    return json.dumps(j, ensure_ascii=False)

def generate_readme_update() -> None:
    """Genera/actualiza el README.md"""
    print("[INFO] Generando actualización de README...")
    
    pubspec = get_pubspec_info()
    structure = get_project_structure()
    current_readme = read_file("README.md")
    
    prompt = f"""
Eres un experto técnico en Flutter/Dart. Actualiza el README.md del proyecto.

Información del proyecto:
- Nombre: {pubspec['name']}
- Descripción: {pubspec['description']}
- Versión: {pubspec['version']}

Estructura del proyecto:
{structure}

README actual:
{current_readme[:3000] if current_readme else 'No existe README actual'}

Genera un README.md completo y profesional que incluya:
1. Nombre y descripción del proyecto
2. Badges de estado (si aplica)
3. Requisitos e instalación
4. Estructura del proyecto
5. Uso básico
6. Configuración
7. Contribución
8. Licencia

Devuelve SOLO el contenido del README.md, sin explicaciones adicionales.
"""
    
    try:
        result = call_genai(prompt)
        # Limpiar markdown code blocks
        result = result.strip()
        if result.startswith("```"):
            result = "\n".join(result.split("\n")[1:])
        if result.endswith("```"):
            result = "\n".join(result.split("\n")[:-1])
        
        write_file("README.md", result)
    except Exception as e:
        print(f"[ERROR] Fallo al generar README: {e}")

def generate_architecture_docs() -> None:
    """Genera documentación de arquitectura"""
    print("[INFO] Generando documentación de arquitectura...")
    
    structure = get_project_structure()
    
    # Leer algunos archivos clave para entender la arquitectura
    key_files = ["lib/main.dart"]
    blocs_dir = ROOT / "lib" / "blocs"
    if blocs_dir.exists():
        for f in list(blocs_dir.glob("*.dart"))[:3]:
            key_files.append(str(f.relative_to(ROOT)))
    
    key_contents = ""
    for kf in key_files:
        content = read_file(kf)
        if content:
            key_contents += f"\n--- {kf} ---\n{content[:1500]}\n"
    
    prompt = f"""
Eres un arquitecto de software experto en Flutter. Analiza el proyecto y genera documentación de arquitectura.

Estructura del proyecto:
{structure}

Archivos clave:
{key_contents}

Genera documentación de arquitectura en formato Markdown que incluya:
1. Visión general de la arquitectura
2. Patrón de diseño utilizado (BLoC, Provider, etc.)
3. Capas del proyecto (UI, Business Logic, Data)
4. Flujo de datos
5. Dependencias principales
6. Diagrama de componentes (en texto/ASCII)

Devuelve SOLO el contenido Markdown, sin explicaciones adicionales.
"""
    
    try:
        result = call_genai(prompt)
        result = result.strip()
        if result.startswith("```"):
            result = "\n".join(result.split("\n")[1:])
        if result.endswith("```"):
            result = "\n".join(result.split("\n")[:-1])
        
        write_file("docs/ARCHITECTURE.md", result)
    except Exception as e:
        print(f"[ERROR] Fallo al generar docs de arquitectura: {e}")

def generate_api_docs() -> None:
    """Genera documentación de API para servicios públicos"""
    print("[INFO] Generando documentación de API...")
    
    services_dir = ROOT / "lib" / "services"
    if not services_dir.exists():
        print("[WARN] No se encontró directorio de servicios")
        return
    
    api_docs = "# API Documentation\n\n"
    api_docs += "Documentación generada automáticamente de los servicios del proyecto.\n\n"
    
    for service_file in list(services_dir.glob("*.dart"))[:5]:
        content = service_file.read_text(encoding="utf-8")
        service_name = service_file.stem
        
        prompt = f"""
Eres un documentador técnico. Genera documentación de API para este servicio Flutter/Dart.

Archivo: {service_name}.dart
Contenido:
{content[:3000]}

Genera documentación breve en Markdown que incluya:
1. Descripción del servicio
2. Métodos públicos con sus parámetros y retornos
3. Ejemplo de uso básico

Sé conciso. Devuelve SOLO el contenido Markdown.
"""
        try:
            result = call_genai(prompt)
            api_docs += f"\n## {service_name}\n\n{result}\n"
        except Exception as e:
            print(f"[ERROR] Fallo al documentar {service_name}: {e}")
    
    write_file("docs/API.md", api_docs)

def main():
    print("[START] Generador de Documentación con GenAI")
    
    scope = os.getenv("DOC_SCOPE", "readme").lower()
    target_path = os.getenv("DOC_TARGET_PATH", "")
    
    print(f"[INFO] Alcance: {scope}")
    if target_path:
        print(f"[INFO] Ruta objetivo: {target_path}")
    
    if scope == "all":
        generate_readme_update()
        generate_architecture_docs()
        generate_api_docs()
    elif scope == "readme":
        generate_readme_update()
    elif scope == "architecture":
        generate_architecture_docs()
    elif scope == "api":
        generate_api_docs()
    else:
        print(f"[WARN] Alcance desconocido: {scope}")
    
    print("[END] Generación de documentación completada")

if __name__ == "__main__":
    main()
