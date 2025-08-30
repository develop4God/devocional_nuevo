#!/bin/bash

# Firebase Test Lab - Devocionales Cristianos
# Script para ejecutar todas las pruebas automatizadas

APP_PATH="$1"
PROJECT_ID="$2"

if [ -z "$APP_PATH" ] || [ -z "$PROJECT_ID" ]; then
    echo "Uso: $0 <ruta-al-apk> <project-id>"
    echo "Ejemplo: $0 app-release.apk mi-proyecto-firebase"
    exit 1
fi

# Configuración de dispositivos
DEVICES=(
    "model=Pixel2,version=28,locale=es,orientation=portrait"
    "model=Pixel3,version=29,locale=en,orientation=portrait" 
    "model=walleye,version=30,locale=pt,orientation=portrait"
)

# Lista de scripts de prueba
SCRIPTS=(
    "01_basic_app_navigation.json"
    "02_language_download_test.json"
    "03_devotional_reading_test.json"
    "04_tts_functionality_test.json"
    "05_prayer_management_test.json"
    "06_settings_configuration_test.json"
    "07_favorites_management_test.json"
    "08_share_functionality_test.json"
    "09_progress_tracking_test.json"
    "10_multilingual_functionality_test.json"
    "11_date_navigation_test.json"
    "12_notification_settings_test.json"
    "13_comprehensive_workflow_test.json"
)

echo "🚀 Iniciando pruebas automatizadas para Devocionales Cristianos"
echo "📱 APK: $APP_PATH"
echo "🔥 Proyecto: $PROJECT_ID"
echo "📋 Total de scripts: ${#SCRIPTS[@]}"
echo "📱 Total de dispositivos: ${#DEVICES[@]}"
echo ""

# Contador de pruebas
total_tests=$((${#SCRIPTS[@]} * ${#DEVICES[@]}))
current_test=0

# Ejecutar cada script en cada dispositivo
for script in "${SCRIPTS[@]}"; do
    for device in "${DEVICES[@]}"; do
        ((current_test++))
        echo "🧪 Ejecutando prueba $current_test/$total_tests"
        echo "📄 Script: $script"
        echo "📱 Dispositivo: $device"
        
        # Nombre del test para identificación
        test_name="${script%.json}_$(echo $device | cut -d',' -f1 | cut -d'=' -f2)"
        
        # Ejecutar el test
        gcloud firebase test android robo \
            --app "$APP_PATH" \
            --robo-script "$script" \
            --device "$device" \
            --project "$PROJECT_ID" \
            --timeout 15m \
            --results-bucket="gs://${PROJECT_ID}_test_results" \
            --results-dir="devocionales_$(date +%Y%m%d_%H%M%S)/$test_name" \
            --environment-variables coverage=true,listener=com.example.MyTestListener \
            --async
        
        if [ $? -eq 0 ]; then
            echo "✅ Test iniciado correctamente"
        else
            echo "❌ Error al iniciar el test"
        fi
        echo ""
    done
done

echo "🎉 Todas las pruebas han sido enviadas a Firebase Test Lab"
echo "🔍 Monitorea el progreso en: https://console.firebase.google.com/project/$PROJECT_ID/testlab"
echo ""
echo "📊 Resumen:"
echo "   - Scripts ejecutados: ${#SCRIPTS[@]}"
echo "   - Dispositivos utilizados: ${#DEVICES[@]}"
echo "   - Total de pruebas: $total_tests"
echo ""
echo "⏱️  Tiempo estimado total: 45-60 minutos"
echo "💾 Resultados se guardarán en: gs://${PROJECT_ID}_test_results"