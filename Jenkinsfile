pipeline {
    agent any
    
    environment {
        // Variables validadas y probadas en los micro-jobs
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/home/jenkins/Android/Sdk"
        ANDROID_HOME = "/home/jenkins/Android/Sdk"
        JAVA_HOME = "/usr/lib/jvm/java-11-openjdk-amd64"
        PATH = "${env.PATH}:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/34.0.0:${JAVA_HOME}/bin"
        LANG = "en_US.UTF-8"
        LC_ALL = "en_US.UTF-8"
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                echo '🔄 Obteniendo código fuente...'
                checkout scm
            }
        }
        
        stage('Verificar Entorno') {
            steps {
                echo '🔍 Verificando entorno (basado en micro-jobs exitosos)...'
                sh '''
                    echo "=== VARIABLES DE ENTORNO ==="
                    echo "JAVA_HOME=$JAVA_HOME"
                    echo "ANDROID_HOME=$ANDROID_HOME"  
                    echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
                    echo "FLUTTER_HOME=$FLUTTER_HOME"
                    
                    echo "=== VERIFICANDO HERRAMIENTAS ==="
                    java -version
                    flutter --version
                    sdkmanager --version
                    adb version
                    
                    echo "=== FLUTTER DOCTOR ANDROID ==="
                    flutter doctor | grep -A 3 "Android toolchain" || true
                '''
            }
        }
        
        stage('Configurar Flutter') {
            steps {
                echo '⚙️ Configurando Flutter para Android...'
                sh '''
                    # Configurar Flutter para usar nuestro Android SDK (validado en Job 2.2)
                    flutter config --android-sdk $ANDROID_SDK_ROOT
                    
                    # Verificar configuración
                    flutter config --list | grep -E "(android-sdk|jdk-dir)" || true
                '''
            }
        }
        
        stage('Limpiar y Obtener Dependencias') {
            steps {
                echo '🧹 Limpiando proyecto y obteniendo dependencias...'
                sh '''
                    # Limpiar build anterior
                    flutter clean
                    
                    # Obtener dependencias del proyecto
                    flutter pub get
                    
                    # Verificar que las dependencias se instalaron correctamente
                    ls -la pubspec.yaml
                    flutter pub deps --style=compact || true
                '''
            }
        }
        
        stage('Ejecutar Tests') {
            steps {
                echo '🧪 Ejecutando tests unitarios...'
                script {
                    def testResult = sh(script: 'flutter test', returnStatus: true)
                    if (testResult != 0) {
                        unstable('Tests fallaron pero continuamos el build')
                        echo '⚠️ Algunos tests fallaron, pero el pipeline continúa'
                    } else {
                        echo '✅ Todos los tests pasaron exitosamente'
                    }
                }
            }
        }
        
        stage('Build APK Debug') {
            steps {
                echo '📱 Construyendo APK Debug...'
                sh '''
                    # Build APK debug (rápido para testing)
                    flutter build apk --debug
                    
                    # Verificar que el APK se creó
                    ls -la build/app/outputs/flutter-apk/
                    
                    # Mostrar información del APK
                    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
                    if [ -f "$APK_PATH" ]; then
                        echo "✅ APK Debug creado exitosamente"
                        echo "📊 Tamaño: $(du -h $APK_PATH | cut -f1)"
                    else
                        echo "❌ Error: APK Debug no encontrado"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Build App Bundle Release') {
            steps {
                echo '📦 Construyendo App Bundle Release...'
                sh '''
                    # Build App Bundle para release (optimizado para Play Store)
                    flutter build appbundle --release
                    
                    # Verificar que el App Bundle se creó
                    ls -la build/app/outputs/bundle/release/
                    
                    # Mostrar información del App Bundle
                    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
                    if [ -f "$AAB_PATH" ]; then
                        echo "✅ App Bundle Release creado exitosamente"
                        echo "📊 Tamaño: $(du -h $AAB_PATH | cut -f1)"
                    else
                        echo "❌ Error: App Bundle Release no encontrado"
                        exit 1
                    fi
                '''
            }
        }
        
        stage('Análisis Final') {
            steps {
                echo '📊 Análisis final del build...'
                sh '''
                    echo "=== RESUMEN DEL BUILD ==="
                    echo "✅ Proyecto Flutter construido exitosamente"
                    
                    echo "=== ARTEFACTOS GENERADOS ==="
                    if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
                        echo "📱 APK Debug: $(du -h build/app/outputs/flutter-apk/app-debug.apk | cut -f1)"
                    fi
                    
                    if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
                        echo "📦 App Bundle Release: $(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)"
                    fi
                    
                    echo "=== FLUTTER DOCTOR FINAL ==="
                    flutter doctor --android-licenses > /dev/null 2>&1 || true
                    flutter doctor | grep -E "(Flutter|Android toolchain)" || true
                '''
            }
        }
    }
    
    post {
        always {
            echo '🏁 Pipeline finalizado.'
            
            // Archivar artefactos generados
            script {
                try {
                    archiveArtifacts artifacts: '''
                        build/app/outputs/flutter-apk/*.apk,
                        build/app/outputs/bundle/release/*.aab
                    ''', fingerprint: true, allowEmptyArchive: true
                    echo '📁 Artefactos archivados exitosamente'
                } catch (Exception e) {
                    echo "⚠️ No se pudieron archivar algunos artefactos: ${e.getMessage()}"
                }
            }
        }
        success {
            echo '''
            🎉 ¡Pipeline ejecutado con éxito!
            
            ✅ Entorno verificado y configurado
            ✅ Dependencias Flutter instaladas  
            ✅ Tests ejecutados
            ✅ APK Debug generado
            ✅ App Bundle Release generado
            ✅ Artefactos archivados
            
            🚀 ¡Listo para deployment!
            '''
        }
        failure {
            echo '''
            ❌ Pipeline falló. Revisa los logs para identificar el problema.
            
            🔍 Pasos de debugging recomendados:
            1. Verificar que el repositorio tenga un proyecto Flutter válido
            2. Revisar los logs de la etapa que falló
            3. Confirmar que las dependencias en pubspec.yaml son correctas
            4. Verificar permisos de archivos si es necesario
            
            💡 Recuerda: Los micro-jobs demuestran que el entorno funciona correctamente
            '''
        }
        unstable {
            echo '''
            ⚠️ Pipeline completado con advertencias.
            
            📊 Posibles causas:
            - Tests unitarios fallaron (pero build fue exitoso)
            - Warnings durante la compilación
            - Algunos artefactos opcionales no se generaron
            
            ✅ Los builds principales fueron exitosos
            '''
        }
    }
}
