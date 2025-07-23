pipeline {
    agent any

    environment {
        // Define una variable para la ruta del archivo .env.jenkins
        // Asegúrate de que .env.jenkins esté en la raíz de tu repositorio
        ENV_FILE = "${workspace}/.env.jenkins"
    }

    stages {
        stage('Declarative: Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Load Environment Variables') {
            steps {
                script {
                    // Lee el archivo .env.jenkins y exporta las variables al entorno del pipeline
                    // Requiere el plugin "Pipeline Utility Steps"
                    def envVars = readProperties file: ENV_FILE
                    envVars.each { key, value ->
                        env."${key}" = value
                    }
                    // Opcional: Imprime las variables para depuración
                    sh 'echo "Variables de entorno cargadas:"'
                    sh 'echo "FLUTTER_HOME: $FLUTTER_HOME"'
                    sh 'echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"'
                    sh 'echo "PATH: $PATH"'
                    sh 'echo "Verificando PATH de Flutter: `which flutter`"'
                    sh 'echo "Verificando PATH de ADB: `which adb`"'
                }
            }
        }

        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Check Flutter') {
            steps {
                sh 'flutter --version'
                sh 'flutter doctor'
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
                sh 'flutter test'
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
                sh 'flutter build apk --debug'
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                sh 'flutter build appbundle --release'
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
