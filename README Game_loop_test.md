# Devocional Nuevo - Game Loop Runner Automation

Este proyecto integra pruebas automatizadas de UI usando el runner de **Game Loop** compatible con Firebase Test Lab.  
Incluye scripts para automatizar compilación, instalación, ejecución de intent especial, verificación de resultados y validación del flujo de navegación.

---

## 📦 **Automatización Local / CI**

### **Script PowerShell**

Guarda el siguiente archivo como `run_game_loop.ps1` en la raíz de tu proyecto:

```powershell
# ===============================================
# Script PowerShell: Automatiza runner Game Loop (Flutter)
# Autor: develop4God
# Uso: Ejecuta en PowerShell desde la raíz de tu proyecto Flutter
# ===============================================

# 1. Compilar la APK en modo debug
Write-Host "`n[1/6] Compilando APK en modo debug..."
flutter build apk --debug

# 2. Instalar la APK en el dispositivo/emulador conectado
Write-Host "`n[2/6] Instalando APK en el dispositivo/emulador..."
adb install -r .\build\app\outputs\flutter-apk\app-debug.apk

# 3. Ejecutar el intent especial de Test Lab/Game Loop
Write-Host "`n[3/6] Ejecutando el intent especial TEST_LOOP..."
adb shell am start -a com.google.intent.action.TEST_LOOP -n com.develop4god.devocional_nuevo/.MainActivity

# 4. (Opcional) Verificar logs relacionados con el runner (presiona Ctrl+C para detener si lo usas interactivo)
Write-Host "`n[4/6] Mostrando logs filtrados por 'GameLoopRunner' (Ctrl+C para detener)..."
Start-Job -Name "GameLoopLogcat" -ScriptBlock { adb logcat | findstr GameLoopRunner }
Start-Sleep -Seconds 6 # Espera para ejecución del runner (ajusta si tu test es más largo)

# 5. Verificar existencia del archivo de resultados
Write-Host "`n[5/6] Verificando existencia de results.json..."
$resultsExists = adb shell run-as com.develop4god.devocional_nuevo ls /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/ | Select-String "results.json"

if ($resultsExists) {
    Write-Host "`nArchivo results.json encontrado. Leyendo contenido:"
    $json = adb shell run-as com.develop4god.devocional_nuevo cat /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/results.json
    Write-Host $json

    # 6. (Opcional) Validar que el test fue exitoso
    if ($json -match '"success":true') {
        Write-Host "`n✅ El test automatizado fue exitoso."
    } else {
        Write-Host "`n❌ El test automatizado falló o no terminó correctamente."
    }
} else {
    Write-Host "`nEl archivo results.json NO fue encontrado. Verifica la ejecución del runner y el intent."
}

# 7. (Opcional) Detener el job de logcat para liberar la consola
Stop-Job -Name "GameLoopLogcat" -ErrorAction SilentlyContinue

Write-Host "`n[6/6] Automatización completada."
```

### **Script Bash (Linux/macOS)**

Guarda el siguiente como `run_game_loop.sh` para sistemas Linux/macOS:

```bash
#!/bin/bash
# ===============================================
# Script Bash: Automatiza runner Game Loop (Flutter)
# Autor: develop4God
# Uso: Ejecuta en terminal desde la raíz del proyecto
# ===============================================

echo -e "\n[1/6] Compilando APK en modo debug..."
flutter build apk --debug

echo -e "\n[2/6] Instalando APK en el dispositivo/emulador..."
adb install -r ./build/app/outputs/flutter-apk/app-debug.apk

echo -e "\n[3/6] Ejecutando el intent especial TEST_LOOP..."
adb shell am start -a com.google.intent.action.TEST_LOOP -n com.develop4god.devocional_nuevo/.MainActivity

echo -e "\n[4/6] Mostrando logs filtrados por 'GameLoopRunner' (Ctrl+C para detener)..."
adb logcat | grep GameLoopRunner &
LOG_PID=$!
sleep 6

echo -e "\n[5/6] Verificando existencia de results.json..."
RESULTS_FILE=$(adb shell run-as com.develop4god.devocional_nuevo ls /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/ | grep results.json)

if [ "$RESULTS_FILE" = "results.json" ]; then
    echo -e "\nArchivo results.json encontrado. Leyendo contenido:"
    JSON=$(adb shell run-as com.develop4god.devocional_nuevo cat /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/results.json)
    echo "$JSON"

    if echo "$JSON" | grep -q '"success":true'; then
        echo -e "\n✅ El test automatizado fue exitoso."
    else
        echo -e "\n❌ El test automatizado falló o no terminó correctamente."
    fi
else
    echo -e "\nEl archivo results.json NO fue encontrado. Verifica la ejecución del runner y el intent."
fi

kill $LOG_PID 2>/dev/null

echo -e "\n[6/6] Automatización completada."
```

---

## 🛠️ **Mejores Prácticas**

### 1. **Automatiza todo el flujo**
- Usa scripts para compilar, instalar, ejecutar y validar.
- Así evitas errores humanos y puedes repetir pruebas cuantas veces quieras.

### 2. **Versiona tus runners y scripts**
- Si cambias el flujo de navegación automatizado, sube la nueva versión del runner y documenta el cambio.

### 3. **Valida el archivo de resultados**
- Verifica que se genere correctamente y que el campo `"success": true` esté presente.
- Asegúrate que `activity_log` incluya los pasos esperados.

### 4. **Integra con CI/CD**
- Adapta estos scripts a tu pipeline (por ejemplo, Github Actions, Bitbucket Pipelines).
- Haz que el build falle si el archivo no se genera o el test automatizado no es exitoso.

### 5. **Documenta el flujo de pruebas**
- Deja claro en tu README cómo ejecutar los tests, qué espera el runner y cómo interpretar los resultados.

### 6. **Revisa los logs si hay errores**
- Usa `adb logcat` filtrado para encontrar problemas en la ejecución.
- Si el archivo no se genera, revisa los logs para encontrar la causa.

### 7. **Limpieza y permisos**
- Si tienes problemas con permisos, usa `adb shell run-as ...` como en los scripts.
- Limpia archivos viejos si es necesario.

### 8. **Adapta los scripts si cambias nombre de paquete**
- Cambia `com.develop4god.devocional_nuevo` por tu package name real si lo modificas.

---

## 📝 **Ejemplo de resultado esperado**

Un archivo `results.json` como este:

```json
{
  "success": true,
  "message": "Game loop test completed successfully.",
  "timestamp": "2025-08-06T17:46:44.838476",
  "build_mode": "debug",
  "app_version": "1.0.0",
  "activity_log": [
    "[2025-08-06T17:46:30.717028] Intent detectado: com.google.intent.action.TEST_LOOP",
    "[2025-08-06T17:46:30.722397] Iniciando Game Loop automatizado...",
    "[2025-08-06T17:46:34.724771] Navegando a SettingsPage",
    "[2025-08-06T17:46:37.761147] Regresando de SettingsPage",
    "[2025-08-06T17:46:39.790014] Navegando a FavoritesPage",
    "[2025-08-06T17:46:42.795883] Regresando de FavoritesPage",
    "[2025-08-06T17:46:44.801353] Flujo de navegación de prueba completado.",
    "[2025-08-06T17:46:44.806907] Reportando resultado del test y saliendo..."
  ]
}
```

---

## 🚀 **Preguntas frecuentes**

### ¿Por qué no aparece el archivo results.json?
- Puede que el runner no se ejecutó correctamente.
- El intent no fue recibido.
- Hay problemas de permisos, revisa los logs.

### ¿Puedo ejecutar el runner en Firebase Test Lab?
- Sí. Este flujo está diseñado para Test Lab usando el intent `com.google.intent.action.TEST_LOOP`.

### ¿Puedo modificar el flujo de navegación?
- Sí, edita el método `runAutomatedGameLoop` del runner.

### ¿Puedo adaptar los scripts para otros sistemas de CI?
- Sí, adapta los scripts para el entorno que uses en tu equipo.

---

## 🤝 **Contribuye**

- Si mejoras el runner, agrega ejemplos en esta documentación.
- Si automatizas otros flujos, comparte los scripts y resultados.

---

**¡Listo para automatizar y probar tu app Flutter con Game Loop!**