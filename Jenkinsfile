pipeline {
    agent any

    environment {
        FLUTTER_HOME = "/usr/local/flutter"
        PATH = "${env.FLUTTER_HOME}/bin:${env.PATH}"
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }
        stage('Flutter Pub Get') {
            steps {
                sh 'flutter pub get'
            }
        }
        stage('Flutter Build APK (Debug)') {
            steps {
                sh 'flutter build apk --debug'
            }
        }
        stage('Build Android APK (Debug)') {
            steps {
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_FILE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS')
                ]) {
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
                        '''
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
                        '''
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
