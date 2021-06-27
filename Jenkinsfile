pipeline{
    agent{
        label "nodejs"
    }
    stages{
        // Add the "Deploy" stage here
        stage('Deploy blue container') {
          when { branch "blue"}
          steps {
            sh '''
              oc project simple-app
              oc start-build blueapp --follow --wait
            '''
          }
        }
       stage('Redirect service to blue container') {
         when { branch "blue"}
         steps {
           sh '''
             oc patch route/blue-green -p '{"spec":{"to":{"name":"blueapp"}}}'
           '''
         }
       }
       stage('Deploy green container') {
          when { branch "green"}
          steps {
            sh '''
              oc project simple-app
              oc start-build greenapp --follow --wait
            '''
          }
        }
       stage('Redirect service to green container') {
         when { branch "green"}
         steps {
           sh '''
             oc patch route/blue-green -p '{"spec":{"to":{"name":"greenapp"}}}'
           '''
         }
       }
    }
}
