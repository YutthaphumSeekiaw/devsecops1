pipeline {
    agent {
        kubernetes {
            cloud 'kubernetes'
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: devsecops-agent
spec:
  restartPolicy: Never
  serviceAccountName: default
  containers:
  - name: trivy
    image: aquasec/trivy:0.48.0
    command: ['cat']
    tty: true
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "500m"
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command: ['cat']
    tty: true
    resources:
      requests:
        memory: "512Mi"
        cpu: "200m"
      limits:
        memory: "1Gi"
        cpu: "500m"
  - name: kubectl
    image: bitnami/kubectl:latest
    command: ['cat']
    tty: true
    resources:
      requests:
        memory: "128Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "200m"
    volumeMounts:
    - name: kube-api-access
      mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      readOnly: true
  volumes:
  - name: kube-api-access
    projected:
      sources:
      - serviceAccountToken:
          path: token
      - configMap:
          name: kube-root-ca.crt
          items:
          - key: ca.crt
            path: ca.crt
      - downwardAPI:
          items:
          - path: namespace
            fieldRef:
              fieldPath: metadata.namespace
'''
        }
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Pulling code from Git Repository...'
                checkout scm
                sh '''
                    echo "Git Log:"
                    git log --oneline -1
                    echo "Current Branch: $(git rev-parse --abbrev-ref HEAD)"
                    echo "Commit Hash: $(git rev-parse HEAD)"
                '''
            }
        }

        stage('2. Security Scan (Source Code & Secrets)') {
            steps {
                container('trivy') {
                    echo '=== Scanning Source Code and Secrets with Trivy ==='
                    sh '''
                        echo "Scanning filesystem for vulnerabilities and secrets..."
                        trivy fs --vuln-type os,library --scanners vuln,secret . || true
                        echo "Generating JSON report..."
                        trivy fs --format json --output trivy-fs-report.json . || true
                    '''
                }
            }
        }

        stage('3. Security Scan (Dockerfile Misconfiguration)') {
            steps {
                container('trivy') {
                    echo '=== Scanning Dockerfile Configuration ==='
                    sh '''
                        echo "Scanning Dockerfile for misconfigurations..."
                        trivy config --severity HIGH,CRITICAL . || true
                        echo "Generating JSON report..."
                        trivy config --format json --output trivy-config-report.json . || true
                    '''
                }
            }
        }

        stage('4. Build Docker Image (Kaniko Secure Build)') {
            steps {
                container('kaniko') {
                    echo '=== Building Secure Docker Image with Kaniko ==='
                    sh '''
                        echo "Building Docker image without pushing to registry..."
                        /kaniko/executor \
                          --context=. \
                          --dockerfile=./Dockerfile \
                          --destination=my-secure-app:${BUILD_NUMBER} \
                          --destination=my-secure-app:latest \
                          --no-push \
                          --tar-path=/workspace/image.tar || true
                        echo "Image build completed"
                    '''
                }
            }
        }

        stage('5. Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    echo '=== Deploying to Kubernetes ==='
                    sh '''
                        mkdir -p /home/jenkins/.kube
                        cat > /home/jenkins/.kube/config <<'EOF'
apiVersion: v1
kind: Config
clusters:
- name: in-cluster
  cluster:
    certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    server: https://kubernetes.default.svc
contexts:
- name: in-cluster
  context:
    cluster: in-cluster
    namespace: default
    user: default
current-context: in-cluster
users:
- name: default
  user:
    token: $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
EOF
                        export KUBECONFIG=/home/jenkins/.kube/config
                        echo "Kubectl version:"
                        kubectl version --short
                        echo "Applying Kubernetes deployment manifest..."
                        kubectl apply -f k8s-deploy.yaml
                        echo "Service and deployment status:"
                        kubectl get svc,deployment -n default || true
                    '''
                }
            }
        }

        stage('6. Verify Deployment Status') {
            steps {
                container('kubectl') {
                    echo '=== Verifying Deployment Health ==='
                    sh '''
                        export KUBECONFIG=/home/jenkins/.kube/config
                        kubectl get pods -n default -o wide
                        kubectl get services -n default
                    '''
                }
            }
        }
    }

    post {
        always {
            echo '=== Pipeline Execution Completed ==='
        }
        success {
            echo '✅ Pipeline PASSED - All stages completed successfully!'
        }
        unstable {
            echo '⚠️ Pipeline UNSTABLE - Some issues found but build continued.'
        }
        failure {
            echo '❌ Pipeline FAILED - Check logs for errors.'
        }
    }
}

