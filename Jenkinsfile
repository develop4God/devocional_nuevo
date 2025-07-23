pipeline {
    agent any

    environment {
        ENV_FILE = "${workspace}/.env.jenkins"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Load Environment Variables') {
            steps {
                script {
                    def config = readProperties file: ENV_FILE
                    env.FLUTTER_HOME = config.FLUTTER_HOME
                    env.ANDROID_SDK_ROOT = config.ANDROID_SDK_ROOT

                    // Construimos PATH extendido para uso en WSL
                    env.PATH = "${env.PATH}:${env.FLUTTER_HOME}/bin:${env.ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${env.ANDROID_SDK_ROOT}/platform-tools:${env.ANDROID_SDK_ROOT}/build-tools/34.0.0"

                    echo "Variables cargadas:"
                    echo "FLUTTER_HOME=${env.FLUTTER_HOME}"
                    echo "ANDROID_SDK_ROOT=${env.ANDROID_SDK_ROOT}"
                    echo "PATH=${env.PATH}"
                }
            }
        }

        stage('Check Flutter') {
            steps {
                sh """
                   echo 'Ejecutando flutter doctor vía WSL con entorno correcto'
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter --version
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter doctor
                """
            }
        }

        stage('Install Dependencies') {
            steps {
                sh """
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter clean
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter pub get
                """
            }
        }

        stage('Run Tests') {
            steps {
                sh """
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter test
                """
            }
        }

        stage('Check Java Version') {
            steps {
                withEnv(['LANG=en_US.UTF-8', 'LC_ALL=en_US.UTF-8']) {
                    sh 'java -version'
                }
            }
        }

        stage('Check JAVA_HOME') {
            steps {
                withEnv(['LANG=en_US.UTF-8', 'LC_ALL=en_US.UTF-8']) {
                    sh 'echo "JAVA_HOME is $JAVA_HOME"'
                }
            }
        }

        stage('Build Android Debug APK') {
            steps {
                sh """
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter build apk --debug
                """
            }
        }

        stage('Build Android AAB for Store') {
            steps {
                sh """
                   wsl env FLUTTER_HOME=$FLUTTER_HOME ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT PATH=$PATH flutter build appbundle --release
                """
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
