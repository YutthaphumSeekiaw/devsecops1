# 1. ใช้ Image ที่มีขนาดเล็กและปลอดภัย (Alpine)
FROM node:20-alpine

# 2. กำหนด Working Directory
WORKDIR /app

# 3. คัดลอกไฟล์โปรเจกต์
COPY package*.json ./
RUN npm install
COPY . .

# 4. DevSecOps Touch: ไม่รันแอปด้วยสิทธิ์ Root (ลดความเสี่ยงโดนยึด Container)
USER node

# 5. เปิดพอร์ตและสั่งรันแอป
EXPOSE 3000
CMD ["node", "app.js"]
