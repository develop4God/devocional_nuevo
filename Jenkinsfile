pipeline {
    agent any

    environment {
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/home/jenkins/Android/Sdk"
        ANDROID_HOME = "/home/jenkins/Android/Sdk"
        JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64"
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
                        flutter clean
                        flutter pub get
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
                        sh '''
                            echo "Usando keystore en: $KEYSTORE_PATH"
                            flutter build appbundle --release
                            AAB_PATH="build/app/outputs/bundle/release/app-release.aab"
                            if [ -f "$AAB_PATH" ]; then
                                echo "App Bundle Release generado correctamente"
                                ls -lh "$AAB_PATH"
                            else
                                echo "Error: App Bundle Release no encontrado"
                                exit 1
                            fi
                        '''
                    }
                }
            }
        }

        // Puedes agregar los stages restantes como tests, debug build, etc, usando la misma técnica
    }

    post {
        always {
            echo 'Pipeline finalizado.'
            archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk,build/app/outputs/bundle/release/*.aab', fingerprint: true, allowEmptyArchive: true
        }
    }
}
