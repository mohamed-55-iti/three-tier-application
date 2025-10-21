FROM nginx:alpine

# تثبيت openssl لتوليد الشهادات
RUN apk add --no-cache openssl

# نسخ ملف التكوين
COPY nginx.conf /etc/nginx/nginx.conf

# نسخ سكريبت توليد SSL
COPY generate-ssl.sh /docker-entrypoint.d/10-generate-ssl.sh

# جعل السكريبت قابل للتنفيذ
RUN chmod +x /docker-entrypoint.d/10-generate-ssl.sh

# فتح المنافذ
EXPOSE 80 443

# الأمر الافتراضي سيتم تشغيله من الصورة الأساسية
