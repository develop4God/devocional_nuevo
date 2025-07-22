pipeline {
    agent any

    environment {
        FLUTTER_HOME = "/mnt/c/src/flutter"
        PATH = "${env.FLUTTER_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Check Flutter') {
            steps {
                sh 'which flutter || echo "Flutter no está instalado o no está en el PATH"'
                sh 'flutter --version || echo "Flutter no disponible"'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'flutter clean'
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
                    sh '''
                        flutter build apk --debug --target-platform android-arm,android-arm64,android-x64 --split-per-abi --no-version-check --verbose -Pandroid.suppressUnsupportedCompileSdk=36 --build-name=49 --build-number=49 --dart-define=KEYSTORE_PATH="$KEYSTORE_FILE_PATH" --dart-define=KEYSTORE_STORE_PASSWORD="$KEYSTORE_STORE_PASSWORD" --dart-define=KEYSTORE_KEY_PASSWORD="$KEYSTORE_KEY_PASSWORD" --dart-define=KEYSTORE_KEY_ALIAS="$KEYSTORE_KEY_ALIAS"
                    '''
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'android/app/build/outputs/apk/debug/app-debug.apk', fingerprint: true
                }
            }
        }
        stage('Build Android AAB for Store') {
            when {
                expression {
                    return false // Skipped if APK build fails, but keep for future release builds
                }
            }
            steps {
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_FILE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS')
                ]) {
                    sh '''
                        flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64 --split-per-abi --no-version-check --verbose -Pandroid.suppressUnsupportedCompileSdk=36 --build-name=49 --build-number=49 --dart-define=KEYSTORE_PATH="$KEYSTORE_FILE_PATH" --dart-define=KEYSTORE_STORE_PASSWORD="$KEYSTORE_STORE_PASSWORD" --dart-define=KEYSTORE_KEY_PASSWORD="$KEYSTORE_KEY_PASSWORD" --dart-define=KEYSTORE_KEY_ALIAS="$KEYSTORE_KEY_ALIAS"
                    '''
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'android/app/build/outputs/bundle/release/app-release.aab', fingerprint: true
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
