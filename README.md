CI/CD Pipeline with Jenkins, Docker, and Kubernetes

🚀 This project demonstrates a production-style CI/CD pipeline that automates the journey from code commit → container image → deployment → verification.
It brings together Jenkins, Docker, and Kubernetes into a cohesive workflow, highlighting modern DevOps practices such as continuous integration, continuous deployment, and automated smoke testing.


📌 Features
- Automated Pipeline.
  Every code commit triggers Jenkins to:
  1) Checkout source code
  2) Build and tag a Docker image
  3) Push the image to Docker Hub
  4) Deploy the updated app to Kubernetes
  5) Run a post-deployment smoke test
    
- Containerized CI/CD
  Jenkins itself runs in Docker, with direct access to the host’s Docker daemon and kubeconfig.

- Zero-Downtime Rollouts
  Kubernetes rolling updates ensure that new versions replace old ones seamlessly.

- Automated Smoke Tests
  Port-forwarding and scripted HTTP checks verify the service is live and healthy after deployment.

- Infrastructure as Code
  Kubernetes manifests (deployment.yaml, service.yaml) define how the app is deployed and exposed inside the cluster.


🛠️ Tech Stack
Jenkins – CI/CD automation server
Docker – Containerization & image registry integration
Kubernetes – Deployment, orchestration, and service management
kubectl – CLI for Kubernetes operations
Docker Hub – Registry for container images


📂 Project Structure
ci-k8s-demo/
├── app/                  # Sample Node.js app
├── k8s/                  # Kubernetes manifests
│   ├── deployment.yaml
│   └── service.yaml
├── Jenkinsfile           # Full CI/CD pipeline definition
├── Dockerfile            # Container build definition
└── README.md             # Documentation


⚙️ How It Works
Code Commit
A commit to the main branch triggers Jenkins.

Build & Push
Jenkins builds a Docker image, tags it with the Git SHA, and pushes it to Docker Hub.

Deploy
Jenkins updates the Kubernetes Deployment with the new image and applies the manifests.

Smoke Test
Jenkins port-forwards the service to verify the application responds correctly.


📉 Current Shortcomings
This project was built for demonstration and learning purposes. Some trade-offs were made that would need to be addressed in a real-world setup:
- Skipping TLS Verification: The Jenkins pipeline currently connects to Kubernetes with --insecure-skip-tls-verify, bypassing certificate validation. This is fine for a local demo but not secure for production.
- Local Single-Node Cluster: The pipeline targets Docker Desktop’s single-node Kubernetes cluster. It doesn’t yet handle multi-node clusters or cloud providers.
- Credentials in Jenkins: Docker Hub credentials are stored in Jenkins, but no secrets manager (e.g., HashiCorp Vault, AWS Secrets Manager) is integrated.
- Minimal Testing: Only a simple smoke test is implemented; there are no unit, integration, or load tests in the pipeline.
- No Monitoring or Alerts: The pipeline verifies rollout status, but there’s no automated rollback or monitoring system in place.

📈 Future Improvements
- Replace insecure TLS handling with proper CA certificates
- Integrate unit & integration test suites into the pipeline
- Harden cluster access (role-based access control, secrets management)
- Extend smoke tests into a full integration test stage
- Add monitoring and automated rollback strategies

Experiment with GitOps tools (ArgoCD, Flux)

Deploy to a multi-node cloud-hosted Kubernetes cluster
