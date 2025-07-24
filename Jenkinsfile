pipeline {
    agent any
    environment {
    FLUTTER_HOME = "/opt/flutter"
    PATH = "${env.PATH}:${FLUTTER_HOME}/bin"
}
    stages {
        stage('Test PATH') {
            steps {
                sh 'echo $PATH'
            }
        }
    }
}
