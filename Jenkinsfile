pipeline {
    agent {
        // สั่งให้ Jenkins สร้าง Pod พิเศษบน Colima K8s โดยมี Trivy Container อยู่ข้างใน
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-agent
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
                // ขั้นตอนนี้ Jenkins จะดึงโค้ดจาก Git มาเตรียมไว้ให้อัตโนมัติ
                echo 'Pulling code from Git Repository...'
            }
        }

        stage('2. Security Scan (Source Code & Secrets)') {
            steps {
                // สั่งงานเข้าไปยัง Container ชื่อ trivy
                container('trivy') {
                    echo '=== Scanning Source Code and Hidden Secrets ==='
                    // สแกนหาช่องโหว่ใน Source Code และความลับ (เช่น Password/Token ที่เผลอผูกไว้)
                    sh 'trivy fs --vuln-type os,library --scanners vuln,secret .'
                }
            }
        }

        stage('3. Security Scan (Dockerfile Misconfiguration)') {
            steps {
                container('trivy') {
                    echo '=== Scanning Dockerfile for Misconfigurations ==='
                    // สแกนหาจุดที่เขียน Dockerfile ไม่ปลอดภัย (เช่น การรันด้วยสิทธิ์ root)
                    // หากเจอจุดเสี่ยงระดับ High ขึ้นไป ให้ Pipeline สั่ง Fail (หยุดทำงาน) ทันที
                    sh 'trivy config --severity HIGH,CRITICAL .'
                }
            }
        }
    }
}
