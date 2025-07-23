pipeline {
    agent any

    environment {
        FLUTTER_HOME = '/mnt/c/src/flutter'
        ANDROID_HOME = '/opt/android-sdk'
        ANDROID_SDK_ROOT = '/opt/android-sdk'
        PUB_CACHE = '/var/lib/jenkins/.pub-cache'
        PATH = "$PATH:/mnt/c/src/flutter/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/34.0.0"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Flutter Clean & Pub Get') {
            steps {
                dir('/var/lib/jenkins/workspace/Devocional_nuevo_Android_CI') {
                    sh '''
                        flutter clean
                        flutter pub cache clean --force
                        flutter pub get
                    '''
                }
            }
        }

        stage('Run Tests') {
            steps {
                dir('/var/lib/jenkins/workspace/Devocional_nuevo_Android_CI') {
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
                dir('/var/lib/jenkins/workspace/Devocional_nuevo_Android_CI') {
                    sh 'flutter build apk --debug'
                }
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                dir('/var/lib/jenkins/workspace/Devocional_nuevo_Android_CI') {
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