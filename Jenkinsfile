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
        // Asegúrate de que esta ruta coincida con la instalación de Flutter en tu imagen Docker
        // Por ejemplo, si lo instalaste en /opt/flutter en el Dockerfile
        FLUTTER_HOME = '/opt/flutter'
        PATH = "${FLUTTER_HOME}/bin:${PATH}"
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
                // Limpiar la caché de pub para evitar problemas de permisos o corrupción.
                sh 'flutter pub cache clean' // <-- NUEVA LÍNEA AÑADIDA AQUÍ

                // Asegura que el usuario 'jenkins' tenga permisos de escritura en el directorio del workspace.
                // Esto es crucial para que 'flutter pub get' pueda escribir en .dart_tool/
                // 'sudo' ahora estará disponible en la imagen Docker.
                sh 'sudo chown -R jenkins:jenkins .' // Cambia el propietario del directorio actual y su contenido
                sh 'sudo chmod -R u+w .' // Otorga permisos de escritura al propietario (jenkins)

                // Ejecuta 'flutter pub get' para descargar los paquetes necesarios.
                sh 'flutter pub get'
            }
        }

        // Etapa 3: Ejecutar las pruebas automatizadas de tu aplicación.
        stage('Run Tests') {
            steps {
                // Ejecuta todas las pruebas definidas en tu proyecto Flutter.
                sh 'flutter test'
            }
        }

        // Etapa 4: Construir el APK de depuración/desarrollo.
        // Este APK es útil para pruebas rápidas en dispositivos o emuladores durante el desarrollo.
        stage('Build Android Debug APK') {
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

        // Etapa 5: Construir el Android App Bundle (AAB) para la tienda.
        // El AAB es el formato recomendado por Google para subir a Google Play Store.
        stage('Build Android AAB for Store') {
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
