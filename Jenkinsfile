pipeline {
    agent any

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Check Flutter') {
            steps {
               withEnv([
                   'FLUTTER_HOME=/mnt/c/src/flutter',
                   'PATH+FLUTTER=/mnt/c/src/flutter/bin',
                   'PUB_CACHE=/var/lib/jenkins/.pub-cache',
                   'ANDROID_HOME=/opt/android-sdk',
                   'ANDROID_SDK_ROOT=/opt/android-sdk',
                   'PATH+ANDROID=/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/34.0.0'
               ]) {
                   sh 'flutter clean'
                   sh 'flutter pub cache clean --force'
                   sh 'flutter pub get'
               }
            }
        }

        stage('Install Dependencies') {
            steps {
                withEnv([
                    'FLUTTER_HOME=/mnt/c/src/flutter',
                    'PATH+FLUTTER=/mnt/c/src/flutter/bin',
                    'ANDROID_HOME=/opt/android-sdk',
                    'ANDROID_SDK_ROOT=/opt/android-sdk',
                    'PATH+ANDROID=/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/34.0.0'
                ]) {
                    sh 'flutter clean'
                    sh 'flutter pub cache clean --force'
                    sh 'flutter pub get'
                }
            }
        }

        stage('Run Tests') {
            steps {
                withEnv([
                    'FLUTTER_HOME=/mnt/c/src/flutter',
                    'PATH+FLUTTER=/mnt/c/src/flutter/bin',
                    'ANDROID_HOME=/opt/android-sdk',
                    'ANDROID_SDK_ROOT=/opt/android-sdk',
                    'PATH+ANDROID=/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/34.0.0'
                ]) {
                    sh 'flutter test'
                }
            }
        }

        stage('Check Java Version') {
            steps {
                sh 'java -version'
            }
        }

        stage('Check JAVA_HOME') {
            steps {
                sh 'echo "JAVA_HOME is $JAVA_HOME"'
            }
        }

        stage('Build Android Debug APK') {
            steps {
                withEnv([
                    'FLUTTER_HOME=/mnt/c/src/flutter',
                    'PATH+FLUTTER=/mnt/c/src/flutter/bin',
                    'ANDROID_HOME=/opt/android-sdk',
                    'ANDROID_SDK_ROOT=/opt/android-sdk',
                    'PATH+ANDROID=/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/34.0.0'
                ]) {
                    sh 'flutter build apk --debug'
                }
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                withEnv([
                    'FLUTTER_HOME=/mnt/c/src/flutter',
                    'PATH+FLUTTER=/mnt/c/src/flutter/bin',
                    'ANDROID_HOME=/opt/android-sdk',
                    'ANDROID_SDK_ROOT=/opt/android-sdk',
                    'PATH+ANDROID=/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/34.0.0'
                ]) {
                    sh 'flutter build appbundle --release'
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finalizado.'
        }
        success {
            echo '¡El pipeline se ejecutó con éxito!'
        }
        failure {
            echo '¡El pipeline falló! Revisa los logs para depurar el problema.'
        }
    }
}
