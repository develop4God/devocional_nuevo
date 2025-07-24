pipeline {
    agent any
    environment {
        FLUTTER_HOME = "/opt/flutter"
        PATH+FLUTTER = "${FLUTTER_HOME}/bin"
    }
    stages {
        stage('Test PATH') {
            steps {
                sh 'echo $PATH'
            }
        }
    }
}
