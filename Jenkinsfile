pipeline {
    agent any
    environment {
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/home/jenkins/Android/Sdk"
        ANDROID_HOME = "/home/jenkins/Android/Sdk"
        JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64"
        // Memoria conservadora para equipos con 4GB RAM
        GRADLE_OPTS = '-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs="-Xmx1500m -XX:MaxMetaspaceSize=384m -XX:+HeapDumpOnOutOfMemoryError"'
        ORG_GRADLE_PROJECT_android_useAndroidX = 'true'
        // Gradle usa el workspace para evitar conflictos con otros jobs
        GRADLE_USER_HOME = "${WORKSPACE}/.gradle"
    }
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Verificar Entorno y Memoria') {
            steps {
                echo 'Verificando entorno...'
                withEnv([
                    "PATH+FLUTTER=${FLUTTER_HOME}/bin",
                    "PATH+CMDLINE=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+PLATFORM_TOOLS=${ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+BUILD_TOOLS=${ANDROID_SDK_ROOT}/build-tools/34.0.0",
                    "PATH+JAVA=${JAVA_HOME}/bin"
                ]) {
                    sh '''
                        echo "PATH actual: $PATH"
                        which sdkmanager
                        sdkmanager --version
                        ls -la "$ANDROID_SDK_ROOT/platforms/"
                        ls -la "$ANDROID_SDK_ROOT/build-tools/"
                        ls -la "$ANDROID_SDK_ROOT/platform-tools/"
                        which flutter
                        flutter --version
                        which java
                        java --version
                        echo "Memoria disponible:"
                        free -h
                        echo "Espacio en disco:"
                        df -h .
                        echo "Swap configurada:"
                        cat /proc/swaps || true
                        # Comenzar monitor de memoria en background
                        (while true; do free -h; sleep 10; done) &
                        MEM_MONITOR_PID=$!
                    '''
                }
            }
        }
        stage('🧹 Limpiar Sistema') {
            steps {
                echo '🧹 Eliminando procesos y caché Gradle previos...'
                sh '''
                    echo "📊 Estado inicial del sistema:"
                    free -h

                    # Identificar y eliminar procesos Gradle
                    pkill -9 -f gradle || true
                    pkill -9 -f GradleDaemon || true
                    sleep 2

                    # Limpiar daemons y caches locales, tanto global como local
                    rm -rf ~/.gradle/daemon/ || true
                    rm -rf ~/.gradle/caches/ || true
                    rm -rf .gradle/ || true
                    rm -rf build/.gradle/ || true

                    echo "📊 Estado después de limpieza:"
                    free -h
                '''
            }
        }
        stage('Limpiar y Obtener Dependencias') {
            steps {
                withEnv([
                    "PATH+FLUTTER=${FLUTTER_HOME}/bin"
                ]) {
                    sh '''
                        flutter clean
                        flutter pub get

                        # Crear o sobrescribir gradle.properties con memoria ajustada y sin daemon, ni parallel, ni configureondemand
                        cat <<EOF > android/gradle.properties
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx1500m -XX:MaxMetaspaceSize=384m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.parallel=false
org.gradle.configureondemand=false
android.useAndroidX=true
android.enableJetifier=true
EOF

                        echo "Configuración gradle.properties aplicada:"
                        cat android/gradle.properties
                    '''
                }
            }
        }
        stage('Build App Bundle Release') {
            steps {
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEY_ALIAS')
                ]) {
                    withEnv([
                        "PATH+FLUTTER=${FLUTTER_HOME}/bin",
                        "PATH+CMDLINE=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                        "PATH+PLATFORM_TOOLS=${ANDROID_SDK_ROOT}/platform-tools",
                        "PATH+BUILD_TOOLS=${ANDROID_SDK_ROOT}/build-tools/34.0.0",
                        "PATH+JAVA=${JAVA_HOME}/bin"
                    ]) {
                        script {
                            sh '''
                                echo "Preparando build. Limpieza final de Gradle..."
                                pkill -9 -f gradle || true
                                pkill -9 -f GradleDaemon || true
                                rm -rf ~/.gradle/daemon/ || true
                                sleep 2

                                echo "Memoria antes del build:"
                                free -h

                                # Build directo con opciones para bajo consumo
                                timeout 600 flutter build appbundle --release --no-tree-shake-icons --verbose

                                echo "Memoria después del build:"
                                free -h

                                # Validación del artefacto AAB
                                AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
                                if [ -f "$AAB_PATH" ]; then
                                    echo "🎉 App Bundle generado correctamente: $AAB_PATH"
                                    ls -lh "$AAB_PATH"
                                else
                                    echo "⚠️  App Bundle no encontrado."
                                    echo "Buscando .aab alternativos..."
                                    find build -name "*.aab" || true
                                    exit 1
                                fi
                            '''
                        }
                    }
                }
            }
        }
        stage('Verificar Artefactos') {
            steps {
                sh '''
                    echo "Verificando artefactos generados (.aab y .apk):"
                    find build -name "*.aab" -o -name "*.apk" || true
                '''
            }
        }
        stage('🧼 Limpieza Final y Recursos') {
            steps {
                sh '''
                    # Detener monitor de memoria
                    kill $MEM_MONITOR_PID >/dev/null 2>&1 || true

                    # Limpieza de procesos y caches
                    pkill -9 -f gradle || true
                    pkill -9 -f GradleDaemon || true
                    rm -rf ~/.gradle/daemon/ || true
                    rm -rf ~/.gradle/caches/ || true
                    rm -rf .gradle/ || true
                    rm -rf build/.gradle/ || true

                    echo "📊 Estado final de memoria:"
                    free -h
                '''
            }
        }
    }
    post {
        always {
            echo '🏁 Pipeline finalizado.'
            sh '''
                pkill -f gradle || true
                pkill -f GradleDaemon || true
                free -h
            '''
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk,build/app/outputs/bundle/release/*.aab',
                              fingerprint: true,
                              allowEmptyArchive: true
            // Opcional: Guardar logs de memoria para análisis futuro
            archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
        }
        success {
            echo '🎉 Build completado exitosamente'
        }
        failure {
            echo '💥 Build falló'
            sh '''
                echo "Información de debug de memoria y procesos:"
                free -h
                df -h .
                ps aux | grep gradle || true
                ls -la build/ || true
                echo "Verifica el log del sistema (dmesg) si hay OOM Killer:"
                dmesg | tail -20 || true
            '''
        }
        cleanup {
            sh '''
                rm -rf .gradle/ || true
                rm -rf build/.gradle/ || true
            '''
        }
    }
}
