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
        steps{
            sh '''
            set -eu
            KUBECTL_DIR="$WORKSPACE/bin"
            KUBECTL="$KUBECTL_DIR/kubectl"
            mkdir -p "$KUBECTL_DIR"

            if [ ! -x "$KUBECTL" ]; then
                VER=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
                curl -sL -o "$KUBECTL" "https://storage.googleapis.com/kubernetes-release/release/${VER}/bin/linux/amd64/kubectl"
                chmod +x "$KUBECTL"
            fi

            export PATH="$KUBECTL_DIR:$PATH"

            kubectl version --client
            kubectl get ns

            kubectl apply -f k8s/service.yaml
            kubectl apply -f k8s/deployment.yaml
            kubectl set image deployment/ci-k8s-demo app=${FULL_TAG} --record
            kubectl rollout status deployment/ci-k8s-demo --timeout=120s
            '''
        }
    }
  }
  post {
    success { echo "Deployed ${FULL_TAG}" }
    failure { echo "Pipeline failed — check logs." }
  }
}