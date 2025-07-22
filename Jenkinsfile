pipeline {
    agent any

    // Eliminamos el bloque 'environment' global para evitar posibles warnings
    // con la concatenación de PATH y definimos las variables localmente con withEnv.

    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Check Flutter') {
            steps {
                // Definimos FLUTTER_HOME y PATH específicamente para esta etapa
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
                    sh 'which flutter'
                    sh 'flutter --version'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                // Definimos FLUTTER_HOME y PATH específicamente para esta etapa
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
                    sh 'flutter clean'
                    sh 'flutter pub cache clean --force'
                    sh 'flutter pub get'
                }
            }
        }

        stage('Run Tests') {
            steps {
                // Definimos FLUTTER_HOME y PATH específicamente para esta etapa
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
                sh 'ls -l $JAVA_HOME' // Verify JAVA_HOME content
            }
        }

        stage('Build Android Debug APK') {
            steps {
                // Definimos FLUTTER_HOME y PATH específicamente para esta etapa
                withEnv(['FLUTTER_HOME=/mnt/c/src/flutter', 'PATH+FLUTTER=/mnt/c/src/flutter/bin']) {
                    sh 'flutter build apk --debug'
                }
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                // Definimos FLUTTER_HOME y PATH específicamente para esta etapa
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
