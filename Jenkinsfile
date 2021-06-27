pipeline{
    agent{
        label "nodejs"
    }
    stages{
        // Add the "Deploy" stage here
        stage('Deploy') {
          steps {
            sh '''
              oc project deployapp
              oc start-build greeting-service --follow --wait
            '''
          }
        }
    }
}
