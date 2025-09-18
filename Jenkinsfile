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

          # --- Ensure kubectl in PATH ---
          KUBECTL_DIR="$WORKSPACE/bin"
          KUBECTL="$KUBECTL_DIR/kubectl"
          mkdir -p "$KUBECTL_DIR"
          if ! [ -x "$KUBECTL" ]; then
            echo "kubectl not found, downloading to $KUBECTL"
            curl -fsSL -o "$KUBECTL" https://storage.googleapis.com/kubernetes-release/release/v1.31.0/bin/linux/amd64/kubectl
            chmod +x "$KUBECTL"
          fi
          export PATH="$KUBECTL_DIR:$PATH"

          # --- Use Jenkins' kubeconfig ---
          export KUBECONFIG=/var/jenkins_home/.kube/config

          # Names
          J_CLUSTER="docker-desktop-jenkins"
          J_CONTEXT="docker-desktop-jenkins"
          BASE_CTX="docker-desktop"

          # Derive base user/ns (keep these; we only swap the server)
          BASE_USER="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="'"$BASE_CTX"'")].context.user}' || true)"
          NS="$(kubectl config view -o jsonpath='{.contexts[?(@.name=="'"$BASE_CTX"'")].context.namespace}' || true)"
          [ -z "$NS" ] && NS=default

          # Pick a host-reachable name for Docker Desktop's K8s API
          HOST_NAME=""
          for name in kubernetes.docker.internal host.docker.internal; do
            if getent hosts "$name" >/dev/null 2>&1 || nslookup "$name" >/dev/null 2>&1; then
              HOST_NAME="$name"; break
            fi
          done
          [ -z "$HOST_NAME" ] && HOST_NAME="kubernetes.docker.internal"

          # --- IMPORTANT: delete any stale jenkins cluster/context so we don't reuse bad CA state ---
          kubectl config delete-context "$J_CONTEXT"  >/dev/null 2>&1 || true
          kubectl config delete-cluster "$J_CLUSTER"  >/dev/null 2>&1 || true

          # --- Create a fresh cluster entry with insecure-skip-tls-verify (demo-safe) ---
          kubectl config set-cluster "$J_CLUSTER" \
            --server="https://${HOST_NAME}:6443" \
            --insecure-skip-tls-verify=true

          # --- Create a fresh context that uses the same user + namespace as your base ctx ---
          kubectl config set-context "$J_CONTEXT" \
            --cluster="$J_CLUSTER" \
            --user="$BASE_USER" \
            --namespace="$NS"

          # Use it
          kubectl config use-context "$J_CONTEXT"

          # Sanity
          kubectl version --client
          kubectl cluster-info || true
          kubectl get ns

          # --- Deploy ---
          kubectl apply -f k8s/service.yaml
          kubectl apply -f k8s/deployment.yaml
          kubectl set image deployment/ci-k8s-demo app="${FULL_TAG}"
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