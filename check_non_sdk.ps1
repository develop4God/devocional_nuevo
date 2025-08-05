# Script completo para detectar violaciones en versión recién compilada
$packageName = "com.develop4god.devocional_nuevo"

Write-Host "Realizando limpieza completa del proyecto..." -ForegroundColor Green
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get

Write-Host "Construyendo AAB en modo Release..." -ForegroundColor Green
flutter build appbundle --release

Write-Host "Construyendo APK en modo Release para pruebas..." -ForegroundColor Green
flutter build apk --release

Write-Host "Instalando nueva versión APK en dispositivo..." -ForegroundColor Green
adb uninstall $packageName
adb install -r build/app/outputs/flutter-apk/app-release.apk

Write-Host "Limpiando logs anteriores..." -ForegroundColor Green
adb logcat -c

Write-Host "Iniciando la app..." -ForegroundColor Yellow
adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1

Write-Host "Capturando logs específicos de la app durante 20 segundos..." -ForegroundColor Yellow
Write-Host "Navega por diferentes pantallas de la aplicación" -ForegroundColor Yellow

# Capturar solo logs relacionados con tu app y con las violaciones específicas
Start-Process adb -ArgumentList "logcat", "*:W" -NoNewWindow -RedirectStandardOutput "temp_logcat.txt"
Start-Sleep -Seconds 20
Get-Process | Where-Object {$_.ProcessName -eq "adb"} | Stop-Process -Force -ErrorAction SilentlyContinue

# Filtrado más preciso
Get-Content "temp_logcat.txt" |
        Where-Object { $_ -match $packageName -or $_ -match "HiddenApiViolation" } |
        Select-String -Pattern "Accessing hidden|HiddenApiViolation|A hidden method|hidden api" |
        Sort-Object -Unique |
        Out-File -FilePath "refined_violations.log"

Remove-Item "temp_logcat.txt"

$violations = (Get-Content "refined_violations.log" -ErrorAction SilentlyContinue).Count
if ($violations -eq $null -or $violations -eq 0) {
    $violations = 0
    Write-Host "No se detectaron violaciones de API Non-SDK específicas de tu app!" -ForegroundColor Green
    Write-Host "El AAB generado está listo para ser subido a Google Play." -ForegroundColor Green
} else {
    Write-Host "Análisis refinado completado. Resultados guardados en refined_violations.log" -ForegroundColor Green
    Write-Host "Número de violaciones específicas detectadas: $violations" -ForegroundColor Yellow

    # Mostrar las primeras 5 violaciones
    Write-Host "Primeras violaciones detectadas:" -ForegroundColor Yellow
    Get-Content "refined_violations.log" -TotalCount 5 | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}