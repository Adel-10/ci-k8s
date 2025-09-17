pipeline {
  agent any
  environment {
    REGISTRY = 'docker.io'
    IMAGE = 'adel1331/ci-k8s-demo'
  }
  stages {
    stage('Checkout'){ steps { checkout scm } }
    stage('Build & Tag'){
      steps {
        script {
          GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
          FULL_TAG = "${IMAGE}:${GIT_SHA}"
          sh "docker build -t ${FULL_TAG} ."
        }
      }
    }
    stage('Push'){
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'U', passwordVariable: 'P')]) {
          sh '''
            echo "$P" | docker login -u "$U" --password-stdin ${REGISTRY}
          '''
        }
        sh "docker push ${FULL_TAG}"
      }
    }
    stage('Deploy'){
      steps {
        sh '''
          if ! command -v kubectl >/dev/null 2>&1; then
            curl -L -o /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
            chmod +x /tmp/kubectl && mv /tmp/kubectl /usr/local/bin/kubectl
          fi
        '''
        sh """
          kubectl apply -f k8s/service.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl set image deployment/ci-k8s-demo app=${FULL_TAG} --record
          kubectl rollout status deployment/ci-k8s-demo --timeout=120s
        """
      }
    }
  }
  post {
    success { echo "Deployed ${FULL_TAG}" }
    failure { echo "Pipeline failed — check logs." }
  }
}
