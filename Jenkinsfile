// Define el pipeline de Jenkins
pipeline {
    // Agente: Especifica dónde se ejecutará el pipeline. 'any' significa en cualquier agente disponible.
    agent any

    // Entorno: Define variables de entorno que estarán disponibles en todo el pipeline.
    environment {
        // Define una variable para la ruta del archivo .env.jenkins.
        // Asegúrate de que .env.jenkins esté en la raíz de tu repositorio.
        ENV_FILE = "${workspace}/.env.jenkins"
    }

    // Etapas: Define las diferentes fases del pipeline.
    stages {
        // Etapa 1: Checkout SCM (Source Code Management)
        // Esta etapa asegura que el código fuente del repositorio esté disponible en el workspace.
        stage('Declarative: Checkout SCM') {
            steps {
                // Realiza el checkout del código fuente desde el SCM configurado en Jenkins.
                checkout scm
            }
        }

        // Etapa 2: Cargar Variables de Entorno
        // Lee el archivo .env.jenkins y exporta sus variables al entorno del pipeline.
        // Requiere el plugin "Pipeline Utility Steps" para 'readProperties'.
        stage('Load Environment Variables') {
            steps {
                script {
                    // Lee el archivo .env.jenkins.
                    def envVars = readProperties file: ENV_FILE
                    // Itera sobre las variables leídas y las exporta al entorno de Jenkins.
                    envVars.each { key, value ->
                        env."${key}" = value
                    }
                    // Opcional: Imprime algunas variables para depuración.
                    sh 'echo "Variables de entorno cargadas:"'
                    sh 'echo "FLUTTER_HOME: $FLUTTER_HOME"'
                    sh 'echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"'
                    sh 'echo "PATH: $PATH"'
                    sh 'echo "Verificando PATH de Flutter: `which flutter`"'
                    sh 'echo "Verificando PATH de ADB: `which adb`"'
                }
            }
        }

        // Etapa 3: Verificar la instalación de Flutter
        // Ejecuta comandos de Flutter para verificar su versión y el estado de la instalación.
        stage('Check Flutter') {
            steps {
                sh 'flutter --version' // Muestra la versión de Flutter.
                sh 'flutter doctor'    // Ejecuta el doctor de Flutter para verificar dependencias.
            }
        }

        // Etapa 4: Instalar Dependencias
        // Limpia el proyecto, limpia la caché de paquetes y obtiene las dependencias de Flutter.
        stage('Install Dependencies') {
            steps {
                sh 'flutter clean'             // Limpia el proyecto Flutter.
                sh 'flutter pub cache clean --force' // Limpia la caché de paquetes de pub.
                sh 'flutter pub get'           // Obtiene las dependencias del proyecto.
            }
        }

        // Etapa 5: Ejecutar Pruebas
        // Ejecuta las pruebas unitarias y de widget del proyecto Flutter.
        stage('Run Tests') {
            steps {
                sh 'flutter test'
            }
        }

        // Etapa 6: Verificar Versión de Java
        // Asegura que la versión de Java requerida esté instalada.
        stage('Check Java Version') {
            steps {
                sh 'java -version'
            }
        }

        // Etapa 7: Verificar JAVA_HOME
        // Confirma que la variable de entorno JAVA_HOME esté configurada correctamente.
        stage('Check JAVA_HOME') {
            steps {
                sh 'echo "JAVA_HOME is $JAVA_HOME"'
            }
        }

        // Etapa 8: Construir APK de Depuración para Android
        // Genera un archivo APK para propósitos de depuración.
        stage('Build Android Debug APK') {
            steps {
                sh 'flutter build apk --debug'
            }
        }

        // Etapa 9: Construir AAB para la Tienda de Android
        // Genera un Android App Bundle (AAB) optimizado para subir a Google Play Store.
        stage('Build Android AAB for Store') {
            steps {
                sh 'flutter build appbundle --release'
            }
        }
    }

    // Post-acciones: Define acciones a ejecutar después de que el pipeline finaliza,
    // independientemente del resultado o en función de él.
    post {
        // Siempre: Se ejecuta siempre al finalizar el pipeline.
        always {
            echo 'Pipeline finalizado.'
        }
        // Éxito: Se ejecuta si todas las etapas del pipeline se completan con éxito.
        success {
            echo '¡El pipeline se ejecutó con éxito!'
        }
        // Fallo: Se ejecuta si alguna etapa del pipeline falla.
        failure {
            echo '¡El pipeline falló! Revisa los logs para depurar el problema.'
        }
    }
}
