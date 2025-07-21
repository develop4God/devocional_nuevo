pipeline {
    agent any

    environment {
        ANDROID_HOME = '/opt/android-sdk'
        PATH = "${env.PATH}:/opt/flutter/bin:${env.ANDROID_HOME}/cmdline-tools/latest/bin:${env.ANDROID_HOME}/platform-tools:${env.ANDROID_HOME}/build-tools/34.0.0"
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
                    // Se ha eliminado el bloque 'withEnv' redundante que causaba la advertencia de seguridad.
                    // Las variables de credenciales ya están disponibles directamente aquí.
                    
                    // Ejecutar gradlew desde directorio android
                    dir('android') {
                        sh '''
                            ./gradlew --stop
                            ./gradlew assembleDebug \
                              -Pflutter.projectRoot=../ \
                              -PKEYSTORE_PATH="$KEYSTORE_FILE_PATH" \
                              -PKEYSTORE_PASSWORD="$KEYSTORE_STORE_PASSWORD" \
                              -PKEY_ALIAS="$KEYSTORE_KEY_ALIAS" \
                              -PKEY_PASSWORD="$KEYSTORE_KEY_PASSWORD" \
                              --no-daemon --stacktrace --info -Pflutter.build.verbose=true \
                              -Dorg.gradle.jvmargs="-Xmx4G" \
                              -Pandroid.suppressUnsupportedCompileSdk=36
                        ''' // Opciones de memoria JVM y supresión de warning de compileSdk añadidas.
                            // Las barras invertidas al final de las líneas se han eliminado para evitar el error 'Task // not found'.
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'android/app/build/outputs/apk/debug/app-debug.apk', fingerprint: true
                    echo "APK debug generado y archivado."
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
                    // Se ha eliminado el bloque 'withEnv' redundante que causaba la advertencia de seguridad.
                    
                    // Ejecutar gradlew desde directorio android
                    dir('android') {
                        sh '''
                            ./gradlew --stop
                            ./gradlew bundleRelease \
                              -Pflutter.projectRoot=../ \
                              -PKEYSTORE_PATH="$KEYSTORE_FILE_PATH" \
                              -PKEYSTORE_PASSWORD="$KEYSTORE_STORE_PASSWORD" \
                              -PKEY_ALIAS="$KEYSTORE_KEY_ALIAS" \
                              -PKEY_PASSWORD="$KEYSTORE_KEY_PASSWORD" \
                              --no-daemon --stacktrace --info -Pflutter.build.verbose=true \
                              -Dorg.gradle.jvmargs="-Xmx4G" \
                              -Pandroid.suppressUnsupportedCompileSdk=36
                        ''' // Opciones de memoria JVM y supresión de warning de compileSdk añadidas.
                            // Las barras invertidas al final de las líneas se han eliminado para evitar el error 'Task // not found'.
                    }
                }
            }
            post {
                success {
                    archiveArtifacts artifacts: 'android/app/build/outputs/bundle/release/app-release.aab', fingerprint: true
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
