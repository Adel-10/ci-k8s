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
            def GIT_SHA  = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
            def FULL_TAG = "adel1331/ci-k8s-demo:${GIT_SHA}"

            sh "docker build -t ${FULL_TAG} ."
            withCredentials([usernamePassword(credentialsId: 'dockerhub', usernameVariable: 'U', passwordVariable: 'P')]) {
                sh 'echo "$P" | docker login -u "$U" --password-stdin docker.io'
            }
            sh "docker push ${FULL_TAG}"

            // make it available to later stages
            env.FULL_TAG = FULL_TAG
            echo "Exported FULL_TAG=${env.FULL_TAG}"
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
    // stage('Deploy'){
    //   steps{
    //       sh '''
    //       set -eu
    //       KUBECTL_DIR="$WORKSPACE/bin"
    //       KUBECTL="$KUBECTL_DIR/kubectl"
    //       mkdir -p "$KUBECTL_DIR"

    //       if [ ! -x "$KUBECTL" ]; then
    //           VER=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
    //           curl -sL -o "$KUBECTL" "https://storage.googleapis.com/kubernetes-release/release/${VER}/bin/linux/amd64/kubectl"
    //           chmod +x "$KUBECTL"
    //       fi

    //       export PATH="$KUBECTL_DIR:$PATH"

    //       export KUBECONFIG=/var/jenkins_home/.kube/config

    //       kubectl config use-context docker-desktop

    //       CURR_SERVER="$(kubectl config view -o jsonpath='{.clusters[?(@.name=="docker-desktop")].cluster.server}')"
    //       if echo "$CURR_SERVER" | grep -q "127.0.0.1"; then
    //           kubectl config set-cluster docker-desktop --server=https://kubernetes.docker.internal:6443
    //       fi

    //       kubectl cluster-info
    //       kubectl get ns

    //       kubectl apply -f k8s/service.yaml
    //       kubectl apply -f k8s/deployment.yaml
    //       kubectl set image deployment/ci-k8s-demo app=${FULL_TAG} --record
    //       kubectl rollout status deployment/ci-k8s-demo --timeout=120s
    //       '''
    //   }
    // }
    stage('Deploy') {
      steps {
        sh '''
          set -eu

          export KUBECONFIG=/var/jenkins_home/.kube/config

          # Create distinct names so we never touch your local "docker-desktop"
          J_CLUSTER="docker-desktop-jenkins"
          J_CONTEXT="docker-desktop-jenkins"
          J_USER="jenkins-user"

          # If the cluster alias doesn’t exist, create it from the existing docker-desktop
          if ! kubectl config get-clusters | grep -q "^${J_CLUSTER}$"; then
            # read current CA/cert data from docker-desktop
            SERVER=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="docker-desktop")].cluster.server}')
            CA=$(kubectl config view -o jsonpath='{.clusters[?(@.name=="docker-desktop")].cluster.certificate-authority-data}')
            # create jenkins-dedicated cluster and point it to kubernetes.docker.internal
            kubectl config set-cluster "${J_CLUSTER}" \
              --server=https://kubernetes.docker.internal:6443 \
              --certificate-authority-data="${CA}"

            # mirror user/credentials (token/client certs) from current context
            USERNAME=$(kubectl config view -o jsonpath='{.contexts[?(@.name=="docker-desktop")].context.user}')
            USERCFG=$(kubectl config view -o json | jq -r \
              --arg u "$USERNAME" '.users[] | select(.name==$u)')
            echo "$USERCFG" | jq -r '.name="'$J_USER'"' | kubectl config set-credentials "$J_USER" --raw

            # create a new context that uses the same namespace as docker-desktop
            NS=$(kubectl config view -o jsonpath='{.contexts[?(@.name=="docker-desktop")].context.namespace}')
            [ -z "$NS" ] && NS=default
            kubectl config set-context "${J_CONTEXT}" --cluster="${J_CLUSTER}" --user="${J_USER}" --namespace="$NS"
          fi

          # Use the jenkins-only context
          kubectl config use-context "${J_CONTEXT}"


          kubectl apply -f k8s/service.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl set image deployment/ci-k8s-demo app=${FULL_TAG}
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