pipeline {
    // เปลี่ยนจาก agent { kubernetes { ... } } มาเป็น agent any 
    // เพื่อให้ Jenkins รันงานบนพื้นที่ของตัวเองได้ทันที ไม่ต้องเสี่ยงดึง Agent ข้ามเครือข่าย
    agent any

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Pulling code from Git Repository...'
            }
        }

        stage('2. Security Scan (Source Code & Secrets)') {
            steps {
                echo '=== Scanning Source Code and Hidden Secrets with Trivy Container ==='
                // สั่งงานดึง Trivy Image มารันสแกนโฟลเดอร์ปัจจุบันตรงๆ 
                // เทคนิคนี้เรียกว่า Docker-outside-of-Docker (DooD) ปลอดภัยและไม่ติดปัญหาเน็ตเวิร์กคลัสเตอร์
                sh 'docker run --rm -v \$(pwd):/apps aquasec/trivy:0.48.0 fs --vuln-type os,library --scanners vuln,secret /apps'
            }
        }

        stage('3. Security Scan (Dockerfile Misconfiguration)') {
            steps {
                echo '=== Scanning Dockerfile for Misconfigurations ==='
                // สแกนตรวจสอบความปลอดภัยของโครงสร้าง Dockerfile 
                sh 'docker run --rm -v \$(pwd):/apps aquasec/trivy:0.48.0 config --severity HIGH,CRITICAL /apps'
            }
        }
    }
}
