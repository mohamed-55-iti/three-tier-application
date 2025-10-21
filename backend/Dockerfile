# ==========================================
# Stage 1: Build Stage
# ==========================================
FROM golang:1.21-alpine AS builder

# تثبيت الأدوات المطلوبة
RUN apk add --no-cache git

# إعداد مجلد العمل
WORKDIR /app

# نسخ ملفات Go modules
COPY go.mod go.sum* ./

# تحميل المكتبات
RUN go mod download

# نسخ الكود المصدري
COPY . .

# بناء التطبيق
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main .

# ==========================================
# Stage 2: Production Stage
# ==========================================
FROM alpine:latest

# تثبيت الشهادات (للاتصال بالخدمات الخارجية إذا لزم الأمر)
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# نسخ الملف التنفيذي من مرحلة البناء
COPY --from=builder /app/main .

# تعريف المنفذ
EXPOSE 8080

# تشغيل التطبيق
CMD ["./main"]
