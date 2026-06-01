# DevSecOps CI/CD Pipeline with Jenkins & Kubernetes

A comprehensive security-focused CI/CD pipeline running on Colima Kubernetes cluster with Jenkins, Trivy vulnerability scanning, and Kaniko secure container builds.

## 🎯 Overview

This project implements a production-ready DevSecOps pipeline that:
- **Scans** source code and configuration files for vulnerabilities and secrets using Trivy
- **Builds** secure Docker images using Kaniko (rootless container builds)
- **Deploys** applications to Kubernetes with proper security contexts
- **Exposes** services via NodePort for local development access

## 📋 Current Status

### ✅ Fully Operational Components
- **Jenkins Controller**: Running on http://localhost:30080 (Kubernetes NodePort)
- **Application**: Accessible at http://localhost:30300 (nginx test image)
- **Kubernetes Cluster**: Colima (local development environment)
- **Pod Replicas**: 2x my-secure-app pods running with 100% availability

### 🔧 Pipeline Stages

```
Stage 1: Checkout SCM          ✅ Clones repository from GitHub
Stage 2: Security Scan (FS)    ✅ Trivy filesystem & secrets scan
Stage 3: Security Scan (Config)✅ Trivy misconfiguration scan
Stage 4: Registry Setup        ⏸️  Placeholder (skips local registry setup)
Stage 5: Kaniko Build          ✅ Secure container image build
Stage 6: Deploy to K8s         ✅ kubectl apply & rollout status
Stage 7: Verify Status         ✅ Pod & Service health check
Stage 8: Health Check          ✅ Application HTTP access test
```

## 🚀 Quick Start

### Access Points

| Service | URL | Port |
|---------|-----|------|
| Jenkins UI | http://localhost:30080 | 30080 |
| Application | http://localhost:30300 | 30300 |
| Jenkins Agent Service | No direct access (internal) | 30500 |

### Trigger Pipeline

1. **Via Jenkins Web UI:**
   - Navigate to http://localhost:30080
   - Click "devsecops-pipeline" job
   - Click "Build Now"
   - Monitor build progress in console output

2. **Via kubectl:**
   ```bash
   # Trigger new builddatabaseName manual pod
   kubectl describe pod my-secure-app-<pod-id>
   ```

3. **Via git push (if webhook configured):**
   ```bash
   # Make changes, commit, and push
   git commit -am "Your changes"
   git push origin master
   ```

## 📁 Project Structure

```
├── Jenkinsfile                 # 8-stage CI/CD pipeline definition
├── Dockerfile                  # Container image specification
├── jenkins-k8s.yaml           # Jenkins deployment & service
├── k8s-deploy.yaml            # Application deployment & service (nginx:alpine)
├── local-registry.yaml        # Optional: Container registry (not in use)
├── app.js                      # Node.js application entry point
├── package.json               # Node.js dependencies
├── .gitignore                 # Git ignore patterns
└── README.md                  # This file
```

## 🔒 Security Features

### Implemented
- ✅ **Trivy Scanning**: Detects vulnerabilities and secret leaks in source code
- ✅ **Kaniko Builds**: Rootless container builds without privileged access
- ✅ **Security Contexts**: Non-root containers with minimal privileges
- ✅ **Service Account Auth**: Token-based Kubernetes authentication
- ⚠️ **readOnlyRootFilesystem**: Currently disabled (required by Kaniko/Jenkins write operations)

### Recommended for Production
```yaml
securityContext:
  readOnlyRootFilesystem: true        # Requires tmpfs volumes
  runAsNonRoot: true                  # Must use non-root user
  runAsUser: 1000                     # Specific unprivileged UID
  allowPrivilegeEscalation: false     # Prevent privilege escalation
  capabilities:
    drop:
      - ALL                           # Drop all kernel capabilities
```

## 🔧 Configuration

### Jenkins Configuration
- **Location**: Managed via Kubernetes Deployment (jenkins-k8s.yaml)
- **Kubernetes Cloud**: Configured at http://localhost:30080/manage
- **Agent Pod Template**: Defined in Jenkinsfile (trivy+kaniko+kubectl+jnlp containers)
- **Service URLs**:
  - Controller: `http://jenkins-service.default.svc.cluster.local:8080/`
  - Agent Tunnel: `jenkins-service.default.svc.cluster.local:50000`

### Kubernetes Configuration
- **Namespace**: `default` (all resources)
- **Persistent Storage**: PersistentVolumeClaim for Jenkins home (5Gi)
- **Network**: In-cluster DNS with service discovery
- **Image Pull**: IfNotPresent (uses cached layers, pulls if missing)

### Docker Hub Integration
```groovy
// Current Kaniko destination (requires authentication)
--destination=yutthaphum/my-secure-app:${BUILD_NUMBER}
--destination=yutthaphum/my-secure-app:latest
```

**To enable Docker Hub push**, configure credentials in Jenkins:
1. Create Docker Hub account (free tier available)
2. Add credentials to Jenkins Secrets
3. Uncomment Kaniko authentication in Jenkinsfile

## 📊 Build Artifacts

After each successful pipeline run:

- **Trivy Reports**:
  - `trivy-fs-report.json` - Filesystem/library vulnerabilities
  - Trivy config scan output in console logs

- **Docker Images** (when Kaniko push succeeds):
  - `yutthaphum/my-secure-app:${BUILD_NUMBER}`
  - `yutthaphum/my-secure-app:latest`

- **Kubernetes Resources**:
  - Updated deployment replicas
  - Pod logs in `kubectl logs my-secure-app-<pod-id>`

## 🐛 Troubleshooting

### Application Not Accessible on localhost:30300
```bash
# Check service status
kubectl get svc my-secure-app-service

# Check pod status
kubectl get pods -l app=my-secure-app -o wide

# Check pod logs
kubectl logs -l app=my-secure-app
```

### Pipeline Stage Failures
- **Stages 2-3**: Usually pass; check trivy database version
- **Stage 4**: Currently placeholder (ignore failures)
- **Stage 5**: May fail if Docker registry credentials not configured
- **Stages 6-8**: Depend on kubectl container access to cluster

### Jenkins Agent Connection Issues
```bash
# Check agent pod logs
kubectl logs -l jenkins=agent

# Verify service DNS resolution
kubectl exec -it jenkins-<pod-id> -- nslookup jenkins-service.default.svc

# Check Jenkins configuration
# http://localhost:30080/manage > System Configuration > Jenkins Location
```

### kubectl Command Failures
- Avoid complex shell variable assignments in ``heredoc`` blocks
- Use direct kubectl commands with proper flags
- Example fix:
  ```groovy
  // ❌ This fails in kubectl container
  TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
  
  // ✅ This works
  kubectl apply -f manifest.yaml
  ```

## 📈 Extending the Pipeline

### Add a Custom Build Stage
```groovy
stage('Custom: Unit Tests') {
    steps {
        container('trivy') {  // or any container you need
            sh '''
                echo "Running custom tests..."
                # Your test commands here
            '''
        }
    }
}
```

### Add SonarQube Scanning
```groovy
// Add to pod template containers list:
- name: sonarqube
  image: sonarsource/sonar-scanner-cli:latest
  
// Add stage:
stage('Code Quality') {
    steps {
        container('sonarqube') {
            sh 'sonar-scanner -Dsonar.projectKey=devsecops'
        }
    }
}
```

### Enable Docker Hub Push
1. Create Docker Hub account
2. Create personal access token (Settings > Security)
3. Add to Jenkins secrets (http://localhost:30080/manage):
   - Kind: Username with password
   - Username: your-dockerhub-user
   - Password: your-access-token
   - ID: `docker-hub-credentials`

4. Update Jenkinsfile:
```groovy
stage('5. Build Docker Image (Kaniko Secure Build)') {
    steps {
        container('kaniko') {
            withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials',
                                             usernameVariable: 'DOCKER_USER',
                                             passwordVariable: 'DOCKER_PASS')]) {
                sh '''
                    /kaniko/executor \
                      --context=. \
                      --dockerfile=./Dockerfile \
                      --destination=yutthaphum/my-secure-app:${BUILD_NUMBER} \
                      --destination=yutthaphum/my-secure-app:latest \
                      --cache=true
                '''
            }
        }
    }
}
```

## 📝 Git Workflow

```bash
# Clone repository
git clone https://github.com/YutthaphumSeekiaw/devsecops1.git

# Create feature branch
git checkout -b feature/my-feature

# Make changes and test locally
# (Jenkins will run full pipeline on push to master)

# Commit changes
git commit -am "Add my feature"

# Push to master (triggers Jenkins if webhook configured)
git push origin master
```

## 🔗 External Resources

- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Kubernetes on Colima**: https://github.com/abiosoft/colima
- **Trivy Scanner**: https://github.com/aquasecurity/trivy
- **Kaniko**: https://github.com/GoogleContainerRegistry/kaniko
- **CIS Kubernetes Benchmarks**: https://www.cisecurity.org/cis-benchmarks/

## 📋 Implementation Checklist

For production deployment, ensure:
- [ ] Docker Hub credentials configured in Jenkins
- [ ] readOnlyRootFilesystem enabled with tmpfs volumes
- [ ] Network policies restricting pod-to-pod communication
- [ ] Persistent storage backup strategy for Jenkins PVC
- [ ] Resource limits set on all container resources
- [ ] Ingress controller configured for external access
- [ ] TLS certificates for secure communication
- [ ] Audit logging enabled for Kubernetes API
- [ ] Regular security scanning with Trivy integrated in CD
- [ ] Secrets management (e.g., HashiCorp Vault integration)

## 📞 Support

For issues or questions:
1. Check Jenkinsfile syntax: `ssh jenkins@localhost 20022 validate-dsl < Jenkinsfile`
2. Inspect Kubernetes resources: `kubectl describe <resource-type> <name>`
3. Review pod logs: `kubectl logs <pod-name>`
4. Check events: `kubectl get events`

---

**Last Updated**: 2024-12-19  
**Pipeline Version**: 8 stages  
**Kubernetes Cluster**: Colima  
**Status**: ✅ Fully Operational
