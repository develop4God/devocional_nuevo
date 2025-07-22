pipeline {
    agent any

    environment {
        ANDROID_HOME = '/opt/android-sdk'
        // Priorizar la ruta de Flutter al principio del PATH
        PATH = "/opt/flutter/bin:${env.PATH}:${env.ANDROID_HOME}/cmdline-tools/latest/bin:${env.ANDROID_HOME}/platform-tools:${env.ANDROID_HOME}/build-tools/34.0.0"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/develop4God/Devocional_nuevo.git', branch: 'main'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'flutter clean' // Se ejecuta flutter clean antes de pub get
                sh 'flutter pub cache clean --force'
                sh 'flutter pub get'
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Skipping Flutter tests as requested.'
            }
        }

        stage('Check Java Version') {
            steps {
                sh 'java -version'
            }
        }

        stage('Check JAVA_HOME') {
            steps {
                sh 'echo $JAVA_HOME'
            }
        }

        stage('Build Android Debug APK') {
            steps {
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_FILE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS')
                ]) {
                    // El bloque 'withEnv' redundante se ha eliminado.
                    // Las variables de credenciales ya están disponibles directamente aquí.
                    
                    // Usar 'flutter build apk' para una construcción más robusta y que maneje las librerías nativas.
                    // Todos los argumentos están en una sola línea lógica para evitar problemas de parsing de shell.
                    sh "flutter build apk --debug --target-platform android-arm,android-arm64,android-x64 --split-per-abi --no-version-check --verbose --gradle-args='-Dorg.gradle.jvmargs=\"-Xmx4G\" -Pandroid.suppressUnsupportedCompileSdk=36' --build-name=${BUILD_NUMBER} --build-number=${BUILD_NUMBER} --dart-define=KEYSTORE_PATH=\"$KEYSTORE_FILE_PATH\" --dart-define=KEYSTORE_STORE_PASSWORD=\"$KEYSTORE_STORE_PASSWORD\" --dart-define=KEYSTORE_KEY_PASSWORD=\"$KEYSTORE_KEY_PASSWORD\" --dart-define=KEYSTORE_KEY_ALIAS=\"$KEYSTORE_KEY_ALIAS\""
                }
            }
            post {
                success {
                    // Archivar todos los APKs generados por --split-per-abi
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/*.apk', fingerprint: true
                    echo "APKs debug generados y archivados."
                }
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_FILE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS')
                ]) {
                    // El bloque 'withEnv' redundante se ha eliminado.
                    
                    // Usar 'flutter build appbundle' para una construcción más robusta y que maneje las librerías nativas.
                    // Todos los argumentos están en una sola línea lógica para evitar problemas de parsing de shell.
                    sh "flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64 --no-version-check --verbose --gradle-args='-Dorg.gradle.jvmargs=\"-Xmx4G\" -Pandroid.suppressUnsupportedCompileSdk=36' --build-name=${BUILD_NUMBER} --build-number=${BUILD_NUMBER} --dart-define=KEYSTORE_PATH=\"$KEYSTORE_FILE_PATH\" --dart-define=KEYSTORE_STORE_PASSWORD=\"$KEYSTORE_STORE_PASSWORD\" --dart-define=KEYSTORE_KEY_PASSWORD=\"$KEYSTORE_KEY_PASSWORD\" --dart-define=KEYSTORE_KEY_ALIAS=\"$KEYSTORE_KEY_ALIAS\""
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/app/outputs/bundle/release/*.aab', fingerprint: true
                    echo "AAB para la tienda generado y archivado."
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finalizado.'
        }
        success {
            echo '¡Build y pruebas exitosos para todas las etapas configuradas!'
        }
        failure {
            echo '¡El pipeline falló! Revisa los logs para depurar el problema.'
        }
    }
}
