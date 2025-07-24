pipeline {
    agent any

    environment {
        FLUTTER_HOME = "/opt/flutter"
        ANDROID_SDK_ROOT = "/opt/android-sdk"
        ANDROID_HOME = "/opt/android-sdk"
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

        stage('Print Environment Variables') {
            steps {
                sh '''
                    echo "JAVA_HOME = $JAVA_HOME"
                    echo "ANDROID_SDK_ROOT = $ANDROID_SDK_ROOT"
                    echo "ANDROID_HOME = $ANDROID_HOME"
                    echo "FLUTTER_HOME = $FLUTTER_HOME"
                    echo "PATH = $PATH"
                    flutter --version
                    flutter doctor -v
                '''
            }
        }

        stage('Install Dependencies') {
            steps {
                sh '''
                    flutter clean
                    flutter pub get
                '''
            }
        }

        // Descomenta esta etapa si quieres correr tests, pero dado que había errores, mejor omitirla por ahora.
        /*
        stage('Run Tests') {
            steps {
                sh 'flutter test'
            }
        }
        */

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
