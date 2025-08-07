# ===============================================
# Script PowerShell: Automatiza runner Game Loop (Flutter)
# Autor: develop4God
# Uso: Ejecuta en PowerShell desde la raíz de tu proyecto Flutter
# .\run_game_loop.ps1  comando para ejecutar el script
# ===============================================

# 0. Desinstalar la app si existe (simula entorno limpio)
# Write-Host "`n[0/8] Desinstalando la app si existe..."
# adb uninstall com.develop4god.devocional_nuevo

# 1. Compilar la APK en modo debug
Write-Host "`n[1/8] Compilando APK en modo debug..."
flutter build apk --debug

# 2. Instalar la APK en el dispositivo/emulador conectado
Write-Host "`n[2/8] Instalando APK en el dispositivo/emulador..."
$installResult = adb install -r .\build\app\outputs\flutter-apk\app-debug.apk

if ($installResult | Select-String "Success") {
    Write-Host "`n✅ Instalación exitosa del APK."
} else {
    Write-Host "`n❌ Error: La instalación del APK falló. Revisa el output:"
    Write-Host $installResult
    exit 1
}

# 3. Cerrar la app antes de lanzar el intent (por si la instalación la inicia automáticamente)
Write-Host "`n[3/8] Cerrando la app si está abierta..."
adb shell am force-stop com.develop4god.devocional_nuevo

# 4. Ejecutar el intent especial de Test Lab/Game Loop
Write-Host "`n[4/8] Ejecutando el intent especial TEST_LOOP..."
adb shell am start -a com.google.intent.action.TEST_LOOP -n com.develop4god.devocional_nuevo/.MainActivity

# 5. (Opcional) Verificar logs relacionados con el runner (presiona Ctrl+C para detener si lo usas interactivo)
Write-Host "`n[5/8] Mostrando logs filtrados por 'GameLoopRunner' (Ctrl+C para detener)..."
Start-Job -Name "GameLoopLogcat" -ScriptBlock { adb logcat | findstr GameLoopRunner }
Start-Sleep -Seconds 8 # Espera para ejecución del runner (ajusta si tu test es más largo)

# 6. Verificar existencia del archivo de resultados
Write-Host "`n[6/8] Verificando existencia de results.json..."
$resultsExists = adb shell run-as com.develop4god.devocional_nuevo ls /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/ | Select-String "results.json"

if ($resultsExists) {
    Write-Host "`nArchivo results.json encontrado. Leyendo contenido:"
    $json = adb shell run-as com.develop4god.devocional_nuevo cat /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/results.json
    Write-Host $json

    # 7. (Opcional) Validar que el test fue exitoso
    if ($json -match '"success":true') {
        Write-Host "`n✅ El test automatizado fue exitoso."
    } else {
        Write-Host "`n❌ El test automatizado falló o no terminó correctamente."
    }
} else {
    Write-Host "`nEl archivo results.json NO fue encontrado. Verifica la ejecución del runner y el intent."
}

# 8. (Opcional) Detener el job de logcat para liberar la consola
Stop-Job -Name "GameLoopLogcat" -ErrorAction SilentlyContinue

Write-Host "`n[8/8] Automatización completada."