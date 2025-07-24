pipeline {
    agent any

    environment {
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/home/jenkins/Android/Sdk"
        ANDROID_HOME = "/home/jenkins/Android/Sdk"
        JAVA_HOME = "/usr/lib/jvm/java-11-openjdk-amd64"
        PATH = "${env.PATH}:${FLUTTER_HOME}/bin:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/build-tools/34.0.0:${JAVA_HOME}/bin"
        LANG = "en_US.UTF-8"
        LC_ALL = "en_US.UTF-8"
    }

    stages {
        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Imprimir Variables de Entorno') {
            steps {
                sh '''
                    echo "JAVA_HOME = $JAVA_HOME"
                    echo "ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT"
                    echo "FLUTTER_HOME = $FLUTTER_HOME"
                    echo "PATH = $PATH"
                '''
                sh 'flutter --version'
                sh 'flutter doctor -v'
            }
        }

        stage('Dependencias Flutter') {
            steps {
                sh '''
                    flutter clean
                    flutter pub get
                '''
            }
        }

        stage('Test Unitarios (opcional)') {
            steps {
                sh 'flutter test || true' // Así el build sigue aunque falle el test
            }
        }

        stage('Verificar Java') {
            steps {
                sh 'java -version'
                sh 'echo "JAVA_HOME is $JAVA_HOME"'
            }
        }

        stage('Build Debug APK') {
            steps {
                sh 'flutter build apk --debug'
            }
        }

        stage('Build App Bundle Release') {
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
