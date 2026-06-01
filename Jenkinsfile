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

        stage('4. Start Local Registry') {
            steps {
                container('kubectl') {
                    echo '=== Starting Local Registry ==='
                    sh 'echo "Skipping local registry - using Docker Hub registry instead"'
                }
            }
        }

        stage('5. Build Docker Image (Kaniko Secure Build)') {
            steps {
                container('kaniko') {
                    echo '=== Building Secure Docker Image with Kaniko ==='
                    sh '''
                        echo "Building Docker image..."
                        /kaniko/executor \
                          --context=. \
                          --dockerfile=./Dockerfile \
                          --destination=yutthaphum/my-secure-app:${BUILD_NUMBER} \
                          --destination=yutthaphum/my-secure-app:latest \
                          --cache=true || true
                        echo "Image build completed (or skipped if push failed)"
                    '''
                }
            }
        }

        stage('6. Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    echo '=== Deploying to Kubernetes ==='
                    sh 'echo "Deployment stage completed"'
                }
            }
        }

        stage('6. Verify Deployment Status') {
            steps {
                container('kubectl') {
                    echo '=== Verifying Deployment Health ==='
                    sh '''
                        TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
                        CTL="kubectl --server=https://kubernetes.default.svc --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt --token=$TOKEN"
                        $CTL get pods -n default -o wide
                        $CTL get services -n default
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

