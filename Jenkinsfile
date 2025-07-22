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
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
                    sh 'which flutter'
                    sh 'flutter --version'
                    sh 'echo $FLUTTER_HOME'
                    sh 'ls $FLUTTER_HOME/packages/flutter_test'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
                    sh 'flutter clean'
                    sh 'flutter pub cache clean --force'
                    sh 'flutter pub get'
                }
            }
        }

        stage('Run Tests') {
            steps {
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
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
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
                    sh 'flutter build apk --debug'
                }
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
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
