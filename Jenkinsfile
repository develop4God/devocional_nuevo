// Pipeline integrado para máxima confiabilidad - EnvPrep + Build en uno solo
pipeline {
    agent any
    environment {
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/home/jenkins/Android/Sdk"
        ANDROID_HOME = "/home/jenkins/Android/Sdk"
        JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64"
        GRADLE_OPTS = '-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs="-Xmx1500m -XX:MaxMetaspaceSize=384m -XX:+HeapDumpOnOutOfMemoryError"'
        ORG_GRADLE_PROJECT_android_useAndroidX = 'true'
        GRADLE_USER_HOME = "${WORKSPACE}/.gradle"
    }
    options {
        timeout(time: 30, unit: 'MINUTES')
    }
    stages {
        // ============ SECCIÓN ENVPREP - LIMPIEZA TOTAL ============
        stage('🧹 Limpieza Total del Entorno') {
            steps {
                echo '🧹 Iniciando limpieza completa para máxima confiabilidad...'
                sh '''
                    echo "Estado ANTES de limpieza:"
                    free -h
                    
                    echo "Eliminando todos los procesos Gradle..."
                    pkill -9 -f gradle || true
                    pkill -9 -f GradleDaemon || true
                    sleep 3
                    
                    echo "Limpiando directorios y cachés..."
                    rm -rf .gradle/ build/.gradle/ || true
                    rm -rf ~/.gradle/daemon/ || true
                    rm -rf ~/.gradle/caches/ || true
                    
                    echo "Estado DESPUÉS de limpieza:"
                    free -h
                '''
            }
        }
        
        stage('📋 Checkout y Validación') {
            steps {
                echo 'Clonando repositorio en entorno limpio...'
                git branch: 'main', url: 'https://github.com/develop4God/Devocional_nuevo.git'
                sh 'test -f pubspec.yaml || { echo "❌ No se encontró pubspec.yaml"; exit 1; }'
            }
        }
        
        stage('🔧 Verificación Completa del Entorno') {
            steps {
                echo 'Verificando que todo esté configurado correctamente...'
                withEnv([
                    "PATH+FLUTTER=${FLUTTER_HOME}/bin",
                    "PATH+CMDLINE=${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+PLATFORM_TOOLS=${ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+BUILD_TOOLS=${ANDROID_SDK_ROOT}/build-tools/34.0.0",
                    "PATH+JAVA=${JAVA_HOME}/bin"
                ]) {
                    sh '''
                        echo "Verificando herramientas:"
                        which flutter && flutter --version
                        which java && java --version
                        which sdkmanager && sdkmanager --version
                        
                        echo "Verificando Android SDK:"
                        ls -la "$ANDROID_SDK_ROOT/platforms/" | head -5
                        ls -la "$ANDROID_SDK_ROOT/build-tools/" | head -5
                        
                        echo "Estado del sistema:"
                        free -h
                        df -h .
                    '''
                }
            }
        }
        
        stage('🔑 Validación del Keystore') {
            steps {
                script {
                    withCredentials([
                        file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_PATH'),
                        string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                        string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS'),
                        string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD')
                    ]) {
                        sh '''
                            echo "Validando keystore para firma..."
                            keytool -list -v -keystore "${KEYSTORE_PATH}" \\
                                    -storepass "$KEYSTORE_STORE_PASSWORD" \\
                                    -alias "$KEYSTORE_KEY_ALIAS" \\
                                    -keypass "$KEYSTORE_KEY_PASSWORD"
                            
                            if [ $? -eq 0 ]; then
                                echo "✅ Keystore validado exitosamente"
                            else
                                echo "❌ Error en validación del keystore"
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }
        
        stage('📦 Preparación de Dependencias') {
            steps {
                withEnv(["PATH+FLUTTER=${FLUTTER_HOME}/bin"]) {
                    sh '''
                        echo "Limpiando proyecto Flutter..."
                        flutter clean
                        
                        echo "Obteniendo dependencias..."
                        flutter pub get
                        
                        echo "Configurando gradle.properties para máxima estabilidad..."
                        cat <<EOF > android/gradle.properties

org.gradle.jvmargs=-Xmx1500m -XX:MaxMetaspaceSize=384m -XX:+HeapDumpOnOutOfMemoryError
org.gradle.daemon=false
org.gradle.parallel=false
org.gradle.configureondemand=false
android.useAndroidX=true
android.enableJetifier=true
EOF
                        echo "Configuración aplicada:"
                        cat android/gradle.properties
                    '''
                }
            }
        }
        
        // ============ SECCIÓN BUILD - COMPILACIÓN ============
        stage('🚀 Compilación del App Bundle') {
            steps {
                script {
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
                            echo "🚀 Iniciando compilación del App Bundle en entorno limpio..."
                            sh '''
                                echo "Estado de memoria antes de compilación:"
                                free -h
                                
                                echo "Compilando App Bundle..."
                                flutter build appbundle --release --no-tree-shake-icons --verbose
                                
                                echo "Estado de memoria después de compilación:"
                                free -h
                            '''
                            
                            echo "🔍 Buscando artefactos generados..."
                            
                            // Buscar AAB con path relativo para archivado correcto
                            def aabPath = sh(script: "find \"${WORKSPACE}/build/app/outputs/bundle/release\" -name \"*.aab\" -type f -print -quit || true", returnStdout: true).trim()
                            if (aabPath) {
                                echo "🎉 App Bundle encontrado: ${aabPath}"
                                sh "ls -lh \"${aabPath}\""
                                env.AAB_FINAL_PATH = aabPath.replace("${WORKSPACE}/", "")
                            } else {
                                echo "⚠️ App Bundle NO encontrado"
                                sh "find \"${WORKSPACE}/build/app/outputs/bundle\" -name \"*.aab\" || true"
                                env.AAB_FINAL_PATH = ""
                            }
                            
                            // Buscar APK con path relativo  
                            def apkPath = sh(script: "find \"${WORKSPACE}/build/app/outputs/flutter-apk\" -name \"*.apk\" -type f -print -quit || true", returnStdout: true).trim()
                            if (apkPath) {
                                echo "🎉 APK encontrado: ${apkPath}"
                                sh "ls -lh \"${apkPath}\""
                                env.APK_FINAL_PATH = apkPath.replace("${WORKSPACE}/", "")
                            } else {
                                echo "⚠️ APK NO encontrado"
                                env.APK_FINAL_PATH = ""
                            }
                        }
                    }
                }
            }
        }
        
        stage('🧼 Limpieza Final') {
            steps {
                sh '''
                    echo "Limpieza post-compilación..."
                    pkill -9 -f gradle || true
                    pkill -9 -f GradleDaemon || true
                    echo "Estado final:"
                    free -h
                '''
            }
        }
    }
    post {
        always {
            echo '🏁 Pipeline de máxima confiabilidad finalizado.'
            sh '''
                pkill -f gradle || true
                pkill -f GradleDaemon || true
                free -h
            '''
            script {
                def artifactsToArchive = []
                if (env.AAB_FINAL_PATH) {
                    artifactsToArchive.add(env.AAB_FINAL_PATH)
                }
                if (env.APK_FINAL_PATH) {
                    artifactsToArchive.add(env.APK_FINAL_PATH)
                }

                if (artifactsToArchive) {
                    echo "📦 Archivando artefactos: ${artifactsToArchive.join(', ')}"
                    archiveArtifacts artifacts: artifactsToArchive.join(','),
                                     fingerprint: true,
                                     allowEmptyArchive: true
                } else {
                    echo "⚠️ No se encontraron artefactos para archivar"
                }
                
                // Archivar logs para debugging
                archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
            }
        }
        success {
            echo '🎉 ¡Compilación exitosa con máxima confiabilidad!'
        }
        failure {
            echo '💥 Falló la compilación - revisando diagnósticos...'
            sh '''
                echo "Diagnóstico de fallo:"
                free -h
                df -h .
                ps aux | grep gradle || true
                ls -la build/ || true
                dmesg | tail -20 || true
            '''
        }
    }
}