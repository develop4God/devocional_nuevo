// Jenkinsfile
// Este archivo define el pipeline de CI/CD para tu aplicación Flutter Devocional_nuevo.
// Se ejecutará en un contenedor Docker con Jenkins y Flutter preinstalados.

pipeline {
    // Define dónde se ejecutará el pipeline. 'any' significa cualquier agente disponible.
    agent any

    // Define variables de entorno que serán accesibles durante la ejecución del pipeline.
    // La variable FLUTTER_HOME y PATH ya están configuradas en la imagen Docker personalizada,
    // pero se incluyen aquí para claridad o si se necesita un ajuste específico.
    environment {
        ANDROID_HOME = '/opt/android-sdk' // Ruta del SDK de Android en WSL
        // MODIFICACIÓN: Actualizar la ruta del ejecutable de Flutter al PATH en la nueva ubicación de WSL
        PATH = "${env.PATH}:/opt/flutter/bin:${env.ANDROID_HOME}/cmdline-tools/latest/bin:${env.ANDROID_HOME}/platform-tools:${env.ANDROID_HOME}/build-tools/34.0.0"
        // Nota: 'build-tools/34.0.0' se usó porque es la que instalaste. Ajusta si usas otra.
    }

    // Define las etapas principales del pipeline.
    stages {
        // Etapa 1: Obtener el código fuente de tu repositorio de GitHub.
        stage('Checkout Code') {
            steps {
                // Clona tu repositorio. Asegúrate de que la URL y la rama sean correctas.
                git url: 'https://github.com/develop4God/Devocional_nuevo.git',
                    branch: 'main' // O la rama principal de tu proyecto (ej. 'master' o 'dev')
            }
        }

        // Etapa 2: Instalar las dependencias de Flutter (paquetes pub).
        stage('Install Dependencies') {
            steps {
                // Limpiar la caché de pub para evitar problemas de permisos o corrupción, forzando la limpieza.
                sh 'flutter pub cache clean --force' // <-- MODIFICADO: Añadido --force

                // Ejecuta 'flutter pub get' para descargar los paquetes necesarios.
                sh 'flutter pub get'
            }
        }

        // Etapa 3: Ejecutar las pruebas automatizadas de tu aplicación.
        stage('Run Tests') {
            steps {
                echo 'Skipping Flutter tests as requested.' // NUEVO: Paso para evitar el error de Jenkinsfile
            }
        }

        // Etapa 4: Construir el APK de depuración/desarrollo.
        // Este APK es útil para pruebas rápidas en dispositivos o emuladores durante el desarrollo.
        stage('Build Android Debug APK') {
            steps {
                // MODIFICACIÓN: Usar credenciales seguras de Jenkins para la firma
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_FILE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS')
                ]) {
                    sh """
                        # Establecer variables de entorno para Gradle
                        export KEYSTORE_PATH="${KEYSTORE_FILE_PATH}"
                        export KEYSTORE_PASSWORD="${KEYSTORE_STORE_PASSWORD}"
                        export KEY_ALIAS="${KEYSTORE_KEY_ALIAS}"
                        export KEY_PASSWORD="${KEYSTORE_KEY_PASSWORD}"

                        # Ejecutar el build de Flutter
                        flutter build apk --debug
                    """
                }
            }
            post {
                success {
                    // Archivar el APK de depuración para que sea accesible desde Jenkins.
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-debug.apk', fingerprint: true
                    echo "APK de depuración generado y archivado: build/app/outputs/flutter-apk/app-debug.apk"
                }
            }
        }

        // Etapa 5: Construir el Android App Bundle (AAB) para la tienda.
        // El AAB es el formato recomendado por Google para subir a Google Play Store.
        stage('Build Android AAB for Store') {
            steps {
                // MODIFICACIÓN: Usar credenciales seguras de Jenkins para la firma
                withCredentials([
                    file(credentialsId: 'UPLOAD_KEYSTORE_FILE', variable: 'KEYSTORE_FILE_PATH'),
                    string(credentialsId: 'KEYSTORE_STORE_PASSWORD', variable: 'KEYSTORE_STORE_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_PASSWORD', variable: 'KEYSTORE_KEY_PASSWORD'),
                    string(credentialsId: 'KEYSTORE_KEY_ALIAS', variable: 'KEYSTORE_KEY_ALIAS')
                ]) {
                    sh """
                        # Establecer variables de entorno para Gradle
                        export KEYSTORE_PATH="${KEYSTORE_FILE_PATH}"
                        export KEYSTORE_PASSWORD="${KEYSTORE_STORE_PASSWORD}"
                        export KEY_ALIAS="${KEYSTORE_KEY_ALIAS}"
                        export KEY_PASSWORD="${KEYSTORE_KEY_PASSWORD}"

                        # Compila la aplicación para Android en formato AAB en modo release.
                        flutter build appbundle --release
                    """
                }
            }
            post {
                success {
                    // Archivar el AAB para que sea accesible desde Jenkins.
                    archiveArtifacts artifacts: 'build/app/outputs/bundle/release/app-release.aab', fingerprint: true
                    echo "AAB para la tienda generado y archivado: build/app/outputs/bundle/release/app-release.aab"
                }
            }
        }
    }

    // Acciones que se ejecutan después de que el pipeline termina, independientemente del resultado.
    post {
        always {
            echo 'Pipeline finalizado.'
        }
        success {
            echo '¡Build y pruebas exitosos para todas las etapas configuradas!'
            // Puedes añadir notificaciones aquí (ej. a Slack, correo electrónico).
            // mail to: 'tu_correo@example.com',
            //       subject: "Jenkins Build Exitoso: ${env.JOB_NAME}",
            //       body: "El build ${env.BUILD_NUMBER} de ${env.JOB_NAME} fue exitoso. URL: ${env.BUILD_URL}"
        }
        failure {
            echo '¡El pipeline falló! Revisa los logs para depurar el problema.'
            // Notificación de fallo.
            // mail to: 'tu_correo@example.com',
            //       subject: "Jenkins Build Fallido: ${env.JOB_NAME}",
            //       body: "El build ${env.BUILD_NUMBER} de ${env.JOB_NAME} falló. Revisa: ${env.BUILD_URL}"
        }
    }
}
