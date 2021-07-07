node('master') {

    def dockerRegistry = 'quay.io'
    def imageName = "todo-app:${env.BUILD_NUMBER}"
    env.IMAGE_TAG = "${dockerRegistry}/jitjiam/${imageName}"
    def dockerCredentialId = 'DOCKER'
    def clusterip = '192.168.49.2'

    def currentEnvironment = 'blue'
    def newEnvironment = { ->
        currentEnvironment == 'blue' ? 'green' : 'blue'
    }

    stage('SCM') {
        checkout scm
    }

    stage('Docker Image') {
        withDockerRegistry([credentialsId: dockerCredentialId, url: "http://${dockerRegistry}"]) {
                sh """
                    docker build -t "${env.IMAGE_TAG}" .
                    docker push "${env.IMAGE_TAG}"
                """
        }
    }

    stage('Check Env') {
        // check the current active environment to determine the inactive one that will be deployed to
        withKubeConfig([credentialsId: 'JENKINS', serverUrl: 'https://${clusterip}:8443']) {
            // fetch the current service configuration
            sh """
              curl -LO "https://storage.googleapis.com/kubernetes-release/release/v1.20.5/bin/linux/amd64/kubectl"
              chmod u+x ./kubectl
              current_role="\$(./kubectl get services todoapp-service -n greet-ns --output json | jq -r .spec.selector.role )"
              if [ "\$current_role" = null ]; then
                  echo "Unable to determine current environment"
                  exit 1
              fi
              echo "\$current_role" >current-environment
            """
        }

        // parse the current active backend
        currentEnvironment = readFile('current-environment').trim()

        // set the build name
        echo "***************************  CURRENT: $currentEnvironment     NEW: ${newEnvironment()}  *****************************"
        currentBuild.displayName = newEnvironment().toUpperCase() + ' ' + imageName

        env.TARGET_ROLE = newEnvironment()

        // clean the inactive environment
        withKubeConfig([credentialsId: 'JENKINS', serverUrl: 'https://${clusterip}:8443']) {
           sh """
           ./kubectl delete deployment "greet-\$TARGET_ROLE -n greet-ns"
           """
        }
    }

    stage('Deploy') {
        // Apply the deployments to AKS.
        // With enableConfigSubstitution set to true, the variables ${TARGET_ROLE}, ${IMAGE_TAG}, ${KUBERNETES_SECRET_NAME}
        // will be replaced with environment variable values
        withKubeConfig([credentialsId: 'JENKINS', serverUrl: 'https://${clusterip}:8443']) {
           sh """
           ./kubectl create deployment "greet-\$TARGET_ROLE --image=${env.IMAGE_TAG} -n greet-ns"
           """
        }
    }

    def verifyEnvironment = { service ->
        sh """
          endpoint_ip="\$(./kubectl get services '${service}' --output json -n greet-ns | jq -r '.spec.ports[0].nodePort')"
          count=0
          while true; do
              count=\$(expr \$count + 1)
              if curl -m 10 "http://\$endpoint_ip"; then
                  break;
              fi
              if [ "\$count" -gt 30 ]; then
                  echo 'Timeout while waiting for the ${service} endpoint to be ready'
                  exit 1
              fi
              echo "${service} endpoint is not ready, wait 10 seconds..."
              sleep 10
          done
        """
    }

    stage('Verify Staged') {
        // verify the deployment through the corresponding test endpoint
        verifyEnvironment("greet-${newEnvironment()}")
    }

    stage('Switch') {
        // Update the production service endpoint to route to the new environment.
        // With enableConfigSubstitution set to true, the variables ${TARGET_ROLE}
        // will be replaced with environment variable values

    }

    stage('Verify Prod') {
        // verify the production environment is working properly
        verifyEnvironment('todoapp-service')
    }
}
