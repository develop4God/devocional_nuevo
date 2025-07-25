pipeline {
    agent any
    environment {
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/home/jenkins/Android/Sdk"
        ANDROID_HOME = "/home/jenkins/Android/Sdk"
        JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64"
        // Configuraciones para optimizar Gradle
        GRADLE_OPTS = '-Dorg.gradle.daemon=false -Dorg.gradle.jvmargs="-Xmx6g -XX:MaxMetaspaceSize=2g -XX:+HeapDumpOnOutOfMemoryError"'
        ORG_GRADLE_PROJECT_android_useAndroidX = 'true'
        // Limitar procesos paralelos para evitar sobrecarga de memoria
        GRADLE_USER_HOME = "${WORKSPACE}/.gradle"
    }
    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }
        stage('Verificar Entorno') {
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
                    '''
                }
            }
        }
        stage('Limpiar y Obtener Dependencias') {
            steps {
                withEnv([
                    "PATH+FLUTTER=${FLUTTER_HOME}/bin"
                ]) {
                    sh '''
                        # Limpiar procesos gradle previos
                        pkill -f gradle || true
                        
                        flutter clean
                        flutter pub get
                        
                        # Crear gradle.properties optimizado si no existe
                        if [ ! -f android/gradle.properties ]; then
                            touch android/gradle.properties
                        fi
                        
                        # Agregar configuraciones de optimización
                        echo "org.gradle.daemon=false" >> android/gradle.properties
                        echo "org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1g -XX:+HeapDumpOnOutOfMemoryError" >> android/gradle.properties
                        echo "org.gradle.parallel=false" >> android/gradle.properties
                        echo "org.gradle.configureondemand=false" >> android/gradle.properties
                        echo "android.useAndroidX=true" >> android/gradle.properties
                        echo "android.enableJetifier=true" >> android/gradle.properties
                        
                        echo "Configuración gradle.properties:"
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
                            try {
                                sh '''
                                    echo "Usando keystore en: $KEYSTORE_PATH"
                                    
                                    # Limpiar cualquier daemon gradle existente
                                    pkill -f gradle || true
                                    rm -rf ~/.gradle/daemon/ || true
                                    
                                    # Verificar memoria antes del build
                                    echo "Memoria antes del build:"
                                    free -h
                                    
                                    # Build con opciones específicas para CI
                                    flutter build appbundle --release --no-tree-shake-icons --verbose
                                    
                                    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
                                    if [ -f "$AAB_PATH" ]; then
                                        echo "App Bundle Release generado correctamente"
                                        ls -lh "$AAB_PATH"
                                    else
                                        echo "Error: App Bundle Release no encontrado"
                                        echo "Contenido del directorio build:"
                                        find build -name "*.aab" || true
                                        exit 1
                                    fi
                                '''
                            } catch (Exception e) {
                                echo "Build falló, intentando build alternativo..."
                                sh '''
                                    # Método alternativo: usar gradle directamente
                                    cd android
                                    ./gradlew clean --no-daemon --stacktrace
                                    ./gradlew bundleRelease --no-daemon --stacktrace --info
                                '''
                            }
                        }
                    }
                }
            }
        }
        stage('Verificar Artefactos') {
            steps {
                sh '''
                    echo "Verificando artefactos generados:"
                    find build -name "*.aab" -o -name "*.apk" || true
                    
                    AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
                    if [ -f "$AAB_PATH" ]; then
                        echo "✓ App Bundle encontrado: $AAB_PATH"
                        ls -lh "$AAB_PATH"
                        file "$AAB_PATH"
                    else
                        echo "✗ App Bundle no encontrado"
                    fi
                '''
            }
        }
    }
    post {
        always {
            echo 'Pipeline finalizado.'
            
            // Limpiar procesos gradle
            sh 'pkill -f gradle || true'
            
            // Archivar artefactos
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk,build/app/outputs/bundle/release/*.aab', 
                            fingerprint: true, 
                            allowEmptyArchive: true
        }
        success {
            echo '✓ Build completado exitosamente'
        }
        failure {
            echo '✗ Build falló'
            sh '''
                echo "Información de debug:"
                free -h
                df -h .
                ps aux | grep gradle || true
                ls -la build/ || true
            '''
        }
        cleanup {
            // Limpiar archivos temporales
            sh '''
                rm -rf .gradle/ || true
                rm -rf build/.gradle/ || true
            '''
        }
    }
}
