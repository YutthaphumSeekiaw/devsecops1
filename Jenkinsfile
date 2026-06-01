pipeline {
    agent {
        // สั่งให้ Jenkins งอก Pod พิเศษชื่อ trivy-agent ขึ้นมาบน Colima K8s
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: trivy-agent
spec:
  containers:
  - name: trivy
    image: aquasec/trivy:0.48.0
    command: ['cat']
    tty: true
'''
        }
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Pulling code from Git Repository...'
            }
        }

        stage('2. Security Scan (Source Code & Secrets)') {
            steps {
                // สั่งให้รีโมทเข้าไปทำงานข้างในคอนเทนเนอร์ชื่อ trivy ที่เราเตรียมไว้ด้านบน
                container('trivy') {
                    echo '=== Scanning Source Code and Hidden Secrets with Trivy Pod ==='
                    // รันคำสั่งสแกนโดยตรง ไม่ต้องใช้คำว่า "docker run" นำหน้าแล้ว
                    sh 'trivy fs --vuln-type os,library --scanners vuln,secret .'
                }
            }
        }

        stage('3. Security Scan (Dockerfile Misconfiguration)') {
            steps {
                container('trivy') {
                    echo '=== Scanning Dockerfile for Misconfigurations ==='
                    // สแกนตรวจสอบไฟล์โครงสร้าง Dockerfile 
                    sh 'trivy config --severity HIGH,CRITICAL .'
                }
            }
        }
    }
}
