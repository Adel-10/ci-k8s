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

          # 1) Ensure kubectl exists in the workspace and is on PATH
          KUBECTL_DIR="$WORKSPACE/bin"
          KUBECTL="$KUBECTL_DIR/kubectl"
          mkdir -p "$KUBECTL_DIR"
          if ! [ -x "$KUBECTL" ]; then
            echo "kubectl not found, downloading to $KUBECTL"
            curl -fsSL -o "$KUBECTL" https://storage.googleapis.com/kubernetes-release/release/v1.31.0/bin/linux/amd64/kubectl
            chmod +x "$KUBECTL"
          fi
          export PATH="$KUBECTL_DIR:$PATH"

          # 2) Use Jenkins' kubeconfig
          export KUBECONFIG=/var/jenkins_home/.kube/config

          # 3) Create/use a Jenkins-only context so we never touch your local docker-desktop entry
          J_CLUSTER="docker-desktop-jenkins"
          J_CONTEXT="docker-desktop-jenkins"
          BASE_CTX="docker-desktop"

          # Reference the original docker-desktop entries, but don't mutate them
          BASE_USER="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="'"$BASE_CTX"'")].context.user}' || true)"
          NS="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="'"$BASE_CTX"'")].context.namespace}' || true)"
          [ -z "$NS" ] && NS=default

          # Grab CA data (base64) from the base cluster
          CA_DATA="$(kubectl config view -o jsonpath='{.clusters[?(@.name=="'"$BASE_CTX"'")].cluster.certificate-authority-data}' || true)"

          # Create a temporary CA file if CA_DATA exists
          CA_FILE=""
          if [ -n "$CA_DATA" ]; then
            CA_FILE="$WORKSPACE/ca.crt"
            echo "$CA_DATA" | base64 -d > "$CA_FILE"
          fi

          # Create the Jenkins-dedicated cluster if it doesn't exist
          if ! kubectl config get-clusters | grep -qx "$J_CLUSTER"; then
            if [ -n "$CA_FILE" ] && [ -s "$CA_FILE" ]; then
              kubectl config set-cluster "$J_CLUSTER" \
                --server="https://kubernetes.docker.internal:6443" \
                --certificate-authority="$CA_FILE" \
                --embed-certs=true
            else
              # Fallback (less secure): use insecure-skip-tls-verify if no CA available
              echo "WARNING: No CA data found in kubeconfig; using --insecure-skip-tls-verify"
              kubectl config set-cluster "$J_CLUSTER" \
                --server="https://kubernetes.docker.internal:6443" \
                --insecure-skip-tls-verify=true
            fi
          fi

          # Create the Jenkins-dedicated context if missing (reuse the same user)
          if ! kubectl config get-contexts -o name | grep -qx "$J_CONTEXT"; then
            kubectl config set-context "$J_CONTEXT" \
              --cluster="$J_CLUSTER" \
              --user="$BASE_USER" \
              --namespace="$NS"
          fi

          # Use Jenkins-only context
          kubectl config use-context "$J_CONTEXT"

          # Sanity checks
          kubectl version --client
          kubectl cluster-info
          kubectl get ns

          # 4) Deploy as before
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