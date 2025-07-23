// Define el pipeline de Jenkins
pipeline {
    // Agente: Especifica dónde se ejecutará el pipeline. 'any' significa en cualquier agente disponible.
    agent any

    // Entorno: Define variables de entorno que estarán disponibles en todo el pipeline.
    environment {
        // Define la variable para la ruta del archivo .env.jenkins.
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
        // Lee el archivo .env.jenkins y carga las variables en el entorno del pipeline.
        // Requiere el plugin "Pipeline Utility Steps" para 'readProperties'.
        stage('Load Environment Variables') {
            steps {
                script {
                    // Lee el archivo .env.jenkins.
                    def config = readProperties file: ENV_FILE
                    env.FLUTTER_HOME = config.FLUTTER_HOME
                    env.ANDROID_SDK_ROOT = config.ANDROID_SDK_ROOT

                    // Opcional: Imprime las variables para depuración
                    sh 'echo "Variables de entorno cargadas (antes de PATH extendido):"'
                    sh 'echo "FLUTTER_HOME: $FLUTTER_HOME"'
                    sh 'echo "ANDROID_SDK_ROOT: $ANDROID_SDK_ROOT"'
                    sh 'echo "PATH actual: $PATH"' // PATH base de Jenkins
                }
            }
        }

        // Etapa 3: Verificar la instalación de Flutter
        stage('Check Flutter') {
            steps {
                // Aplicar PATH extendido solo a los pasos dentro de esta etapa.
                withEnv([
                    "PATH+FLUTTER_BIN=${env.FLUTTER_HOME}/bin",
                    "PATH+ANDROID_CMD_TOOLS=${env.ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+ANDROID_PLATFORM_TOOLS=${env.ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+ANDROID_BUILD_TOOLS=${env.ANDROID_SDK_ROOT}/build-tools/34.0.0"
                ]) {
                    sh 'echo "PATH dentro de Check Flutter: $PATH"' // Para depuración
                    sh 'which flutter' // Debería encontrar flutter ahora
                    sh 'flutter --version' // Muestra la versión de Flutter.
                    sh 'flutter doctor'    // Ejecuta el doctor de Flutter para verificar dependencias.
                }
            }
        }

        // Etapa 4: Instalar Dependencias
        stage('Install Dependencies') {
            steps {
                // Aplicar PATH extendido solo a los pasos dentro de esta etapa.
                withEnv([
                    "PATH+FLUTTER_BIN=${env.FLUTTER_HOME}/bin",
                    "PATH+ANDROID_CMD_TOOLS=${env.ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+ANDROID_PLATFORM_TOOLS=${env.ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+ANDROID_BUILD_TOOLS=${env.ANDROID_SDK_ROOT}/build-tools/34.0.0"
                ]) {
                    sh 'flutter clean'             // Limpia el proyecto Flutter.
                    sh 'flutter pub cache clean --force' // Limpia la caché de paquetes de pub.
                    sh 'flutter pub get'           // Obtiene las dependencias del proyecto.
                }
            }
        }

        // Etapa 5: Ejecutar Pruebas
        stage('Run Tests') {
            steps {
                // Aplicar PATH extendido solo a los pasos dentro de esta etapa.
                withEnv([
                    "PATH+FLUTTER_BIN=${env.FLUTTER_HOME}/bin",
                    "PATH+ANDROID_CMD_TOOLS=${env.ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+ANDROID_PLATFORM_TOOLS=${env.ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+ANDROID_BUILD_TOOLS=${env.ANDROID_SDK_ROOT}/build-tools/34.0.0"
                ]) {
                    sh 'flutter test'
                }
            }
        }

        // Etapa 6: Verificar Versión de Java (asumiendo que Java está en PATH o JAVA_HOME)
        stage('Check Java Version') {
            steps {
                // No necesita withEnv si Java ya está en el PATH base de Jenkins o vía JAVA_HOME.
                sh 'java -version'
            }
        }

        // Etapa 7: Verificar JAVA_HOME
        stage('Check JAVA_HOME') {
            steps {
                // No necesita withEnv si JAVA_HOME ya está configurado.
                sh 'echo "JAVA_HOME is $JAVA_HOME"'
            }
        }

        // Etapa 8: Construir APK de Depuración para Android
        stage('Build Android Debug APK') {
            steps {
                // Aplicar PATH extendido solo a los pasos dentro de esta etapa.
                withEnv([
                    "PATH+FLUTTER_BIN=${env.FLUTTER_HOME}/bin",
                    "PATH+ANDROID_CMD_TOOLS=${env.ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+ANDROID_PLATFORM_TOOLS=${env.ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+ANDROID_BUILD_TOOLS=${env.ANDROID_SDK_ROOT}/build-tools/34.0.0"
                ]) {
                    sh 'flutter build apk --debug'
                }
            }
        }

        // Etapa 9: Construir AAB para la Tienda de Android
        stage('Build Android AAB for Store') {
            steps {
                // Aplicar PATH extendido solo a los pasos dentro de esta etapa.
                withEnv([
                    "PATH+FLUTTER_BIN=${env.FLUTTER_HOME}/bin",
                    "PATH+ANDROID_CMD_TOOLS=${env.ANDROID_SDK_ROOT}/cmdline-tools/latest/bin",
                    "PATH+ANDROID_PLATFORM_TOOLS=${env.ANDROID_SDK_ROOT}/platform-tools",
                    "PATH+ANDROID_BUILD_TOOLS=${env.ANDROID_SDK_ROOT}/build-tools/34.0.0"
                ]) {
                    sh 'flutter build appbundle --release'
                }
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
