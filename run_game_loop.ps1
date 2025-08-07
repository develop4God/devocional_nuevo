# ===============================================
# Script PowerShell: Automtiza runner Game Loop (Flutter)
# Autor: develop4God
# Uso: Ejecuta en PowerShell desde la raíz de tu proyecto Flutter
# .\run_game_loop.ps1
# ===============================================

# 0. Desinstalar la app si existe (opcional)
# Write-Host "`n[0/8] Desinstalando la app si existe..."
# adb uninstall com.develop4god.devocional_nuevo

# 1. Compilar APK en modo debug
Write-Host "`n[1/8] Compilando APK en modo debug..."
flutter build apk --debug

# 2. Instalar la APK en el dispositivo/emulador
Write-Host "`n[2/8] Instalando APK en el dispositivo/emulador..."
$installResult = adb install -r .\build\app\outputs\flutter-apk\app-debug.apk

if ($installResult | Select-String "Success") {
    Write-Host "`n✅ Instalación exitosa del APK."
} else {
    Write-Host "`n❌ Error: Falló instalación del APK:"
    Write-Host $installResult
    exit 1
}

# Pausa para evitar inicio automático de la app en modo normal
Start-Sleep -Seconds 2

# 3. Forzar cierre de la app para evitar arranque previo no deseado
Write-Host "`n[3/8] Cerrando la app si está abierta..."
adb shell am force-stop com.develop4god.devocional_nuevo

# Esperar que el proceso de la app esté cerrado
for ($i=0; $i -lt 10; $i++) {
    $proc = adb shell pidof com.develop4god.devocional_nuevo
    if ($null -eq $proc -or [string]::IsNullOrEmpty($proc)) {
        Write-Host "✅ App cerrada correctamente."
        break
    } else {
        Write-Host "⏳ Esperando cierre completo de la app..."
        Start-Sleep -Seconds 1
    }
}

if ($proc -and -not [string]::IsNullOrEmpty($proc)) {
    Write-Host "⚠️ La app sigue corriendo. Forzando cierre adicional..."
    adb shell am force-stop com.develop4god.devocional_nuevo
    Start-Sleep -Seconds 2
}

# 4. Lanzar intent especial para que la app inicie en modo Game Loop
Write-Host "`n[4/8] Lanzando intent especial TEST_LOOP para iniciar modo Game Loop..."
adb shell am start -a com.google.intent.action.TEST_LOOP -n com.develop4god.devocional_nuevo/.MainActivity

# 5. Mostrar logs filtrados mientras corre el Game Loop (Ctrl+C para detener si es interactivo)
Write-Host "`n[5/8] Mostrando logs filtrados por 'GameLoopRunner' (Ctrl+C para detener)..."
Start-Job -Name "GameLoopLogcat" -ScriptBlock { adb logcat | findstr GameLoopRunner }

# 6. Esperar dinámicamente a que el archivo results.json esté disponible (hasta 30 seg)
Write-Host "`n[6/8] Esperando que results.json sea creado..."
$maxRetries = 15
$waitSeconds = 15
$foundResults = $false

for ($i=0; $i -lt $maxRetries; $i++) {
    $check = adb shell run-as com.develop4god.devocional_nuevo ls /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/ | Select-String "results.json"
    if ($check) {
        Write-Host "✅ Archivo results.json detectado."
        $foundResults = $true
        break
    } else {
        Write-Host "⏳ Esperando... Quedan $($maxRetries - $i - 1) intentos."
        Start-Sleep -Seconds $waitSeconds
    }
}

if ($foundResults) {
    Write-Host "`n[7/8] Leyendo contenido de results.json..."
    $jsonContent = adb shell run-as com.develop4god.devocional_nuevo cat /data/data/com.develop4god.devocional_nuevo/cache/firebase-test-lab-game-loops/results.json
    Write-Host $jsonContent

    if ($jsonContent -match '"success":true') {
        Write-Host "`n🎉 El test automatizado fue exitoso."
    } else {
        Write-Host "`n⚠️ El test automatizado falló o no terminó correctamente."
    }
} else {
    Write-Host "`n❌ No se encontró results.json en el tiempo esperado."
}

# 8. Detener el job de logcat para liberar consola
Stop-Job -Name "GameLoopLogcat" -ErrorAction SilentlyContinue

Write-Host "`n[8/8] Automatización completada."
