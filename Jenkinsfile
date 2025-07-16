// Jenkinsfile
pipeline {
    agent any // Indica que el pipeline puede ejecutarse en cualquier agente disponible

    // Las variables de entorno para Flutter ya están configuradas en la imagen Docker
    // No necesitamos redefinir FLUTTER_HOME o PATH aquí a menos que sea necesario un ajuste específico
    environment {
        // Asegúrate de que esta ruta coincida con la instalación de Flutter en tu imagen Docker
        // Por ejemplo, si lo instalaste en /opt/flutter en el Dockerfile
        FLUTTER_HOME = '/opt/flutter'
        PATH = "${FLUTTER_HOME}/bin:${PATH}"
    }

    stages {
        stage('Checkout Code') { // Etapa 1: Obtener el código de GitHub
            steps {
                // Clona tu repositorio. Asegúrate de que la URL y la rama sean correctas.
                git url: 'https://github.com/develop4God/Devocional_nuevo.git',
                    branch: 'main' // O la rama principal de tu proyecto (ej. 'master' o 'dev')
            }
        }

        stage('Install Dependencies') { // Etapa 2: Instalar dependencias de Flutter
            steps {
                // Ejecuta 'flutter pub get' para descargar los paquetes necesarios.
                sh 'flutter pub get'
            }
        }

        stage('Run Tests') { // Etapa 3: Ejecutar las pruebas automatizadas de tu aplicación.
            steps {
                // Ejecuta todas las pruebas definidas en tu proyecto Flutter.
                sh 'flutter test'
            }
        }

        stage('Build Android Debug APK') { // Etapa 4: Construir el APK de depuración/desarrollo.
            steps {
                // Compila la aplicación para Android en modo depuración.
                sh 'flutter build apk --debug'
            }
            post {
                success {
                    // Archivar el APK de depuración para que sea accesible desde Jenkins.
                    archiveArtifacts artifacts: 'build/app/outputs/flutter-apk/app-debug.apk', fingerprint: true
                    echo "APK de depuración generado y archivado: build/app/outputs/flutter-apk/app-debug.apk"
                }
            }
        }

        stage('Build Android AAB for Store') { // Etapa 5: Construir el Android App Bundle (AAB) para la tienda.
            steps {
                // Compila la aplicación para Android en formato AAB en modo release.
                // Asegúrate de tener tu keystore configurado si estás firmando para producción.
                // Si no tienes el keystore configurado en el entorno de Jenkins,
                // esta etapa puede fallar o generar un AAB sin firmar.
                sh 'flutter build appbundle --release'
            }
            post {
                success {
                    // Archivar el AAB para que sea accesible desde Jenkins.
                    archiveArtifacts artifacts: 'build/app/outputs/bundle/release/app-release.aab', fingerprint: true
                    echo "AAB para la tienda generado y archivado: build/app/outputs/bundle/release/app-release.aab"
                }
            }
        }

        // --- Opcional: Otras etapas que podrías querer añadir en el futuro ---
        /*
        // Etapa Opcional: Construir la aplicación web de Flutter.
        stage('Build Web App') {
            steps {
                sh 'flutter build web --release'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'build/web/**/*', fingerprint: true
                    echo "Aplicación web generada y archivada en build/web."
                }
            }
        }

        // Etapa Opcional: Despliegue a un entorno de staging o Firebase App Distribution.
        stage('Deploy to Staging/Firebase') {
            steps {
                echo 'Desplegando artefactos...'
                // Aquí irían los comandos para subir el APK/AAB a un servicio de despliegue.
                // Ejemplo para Firebase App Distribution (requiere Firebase CLI y plugin):
                // sh 'firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app <your-app-id> --release-notes "Nueva versión de prueba" --groups "testers"'
            }
        }
        */
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
            //      subject: "Jenkins Build Exitoso: ${env.JOB_NAME}",
            //      body: "El build ${env.BUILD_NUMBER} de ${env.JOB_NAME} fue exitoso. URL: ${env.BUILD_URL}"
        }
        failure {
            echo '¡El pipeline falló! Revisa los logs para depurar el problema.'
            // Notificación de fallo.
            // mail to: 'tu_correo@example.com',
            //      subject: "Jenkins Build Fallido: ${env.JOB_NAME}",
            //      body: "El build ${env.BUILD_NUMBER} de ${env.JOB_NAME} falló. Revisa: ${env.BUILD_URL}"
        }
    }
}
