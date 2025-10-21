# Three-Tier Blog Application

مشروع تطبيق ويب ثلاثي الطبقات (Three-Tier) يتكون من:
- **Backend API** (Go)
- **Database** (MySQL)
- **Reverse Proxy** (Nginx with HTTPS)

يدعم المشروع Docker Compose للتطوير المحلي و Kubernetes للنشر الإنتاجي.

---

## 📁 هيكل المشروع

```
three-tier-app/
├── backend/
│   ├── Dockerfile
│   ├── main.go
│   └── go.mod
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
│   └── generate-ssl.sh
├── K8S/
│   ├── backend_deployment.yaml
│   ├── backend_service.yaml
│   ├── database_deployment.yaml
│   ├── db-service.yaml
│   ├── db-secret.yaml
│   ├── db-data-pv.yaml
│   ├── db-data-pvc.yaml
│   ├── proxy_deployment.yaml
│   └── proxy_nodeport.yaml
├── docker-compose.yaml
├── db-password.txt
└── README.md
```

---

## 🚀 البدء السريع

### المتطلبات الأساسية

- Docker و Docker Compose
- Kubernetes (Minikube أو Kind للتطوير المحلي)
- kubectl
- Git

---

## 🐳 التشغيل باستخدام Docker Compose

### 1. استنساخ المشروع

```bash
git clone <repository-url>
cd three-tier-app
```

### 2. إنشاء ملف كلمة المرور

```bash
echo "MySecurePassword123!" > db-password.txt
```

### 3. بناء وتشغيل الحاويات

```bash
docker-compose up -d --build
```

### 4. التحقق من حالة الخدمات

```bash
docker-compose ps
```

### 5. اختبار التطبيق

```bash
# HTTP (سيتم إعادة التوجيه إلى HTTPS)
curl -k https://localhost/

# الحصول على قائمة المدونات
curl -k https://localhost/blogs

# إضافة مدونة جديدة
curl -k -X POST https://localhost/blogs \
  -H "Content-Type: application/json" \
  -d '{"title":"My New Blog","content":"This is a test","author":"User"}'

# فحص الصحة
curl -k https://localhost/health
```

### 6. عرض السجلات

```bash
# جميع الخدمات
docker-compose logs -f

# خدمة محددة
docker-compose logs -f backend
docker-compose logs -f nginx
docker-compose logs -f mysql
```

### 7. إيقاف التطبيق

```bash
# إيقاف مع الاحتفاظ بالبيانات
docker-compose down

# إيقاف وحذف البيانات
docker-compose down -v
```

---

## ☸️ النشر على Kubernetes

### 1. تثبيت Minikube (للتطوير المحلي)

```bash
# Linux/Mac
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# بدء Minikube
minikube start --driver=docker
```

### 2. بناء ورفع Docker Images

#### الطريقة 1: استخدام Docker Hub

```bash
# تسجيل الدخول
docker login

# بناء الصور
docker build -t your-username/three-tier-backend:latest ./backend
docker build -t your-username/three-tier-nginx:latest ./nginx

# رفع الصور
docker push your-username/three-tier-backend:latest
docker push your-username/three-tier-nginx:latest
```

#### الطريقة 2: استخدام Minikube Registry (للتطوير المحلي)

```bash
# استخدام Docker environment الخاص بـ Minikube
eval $(minikube docker-env)

# بناء الصور داخل Minikube
docker build -t three-tier-backend:latest ./backend
docker build -t three-tier-nginx:latest ./nginx

# تحديث ملفات deployment لاستخدام imagePullPolicy: Never
```

### 3. تشفير كلمة مرور قاعدة البيانات

```bash
# تشفير كلمة المرور إلى Base64
echo -n 'MySecurePassword123!' | base64

# النتيجة: TXlTZWN1cmVQYXNzd29yZDEyMyE=
# ضعها في K8S/db-secret.yaml
```

### 4. تطبيق ملفات Kubernetes

```bash
# تطبيق الملفات بالترتيب

# 1. Secret وتخزين البيانات
kubectl apply -f K8S/db-secret.yaml
kubectl apply -f K8S/db-data-pv.yaml
kubectl apply -f K8S/db-data-pvc.yaml

# 2. قاعدة البيانات
kubectl apply -f K8S/database_deployment.yaml
kubectl apply -f K8S/db-service.yaml

# انتظر حتى تصبح قاعدة البيانات جاهزة
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

# 3. Backend API
kubectl apply -f K8S/backend_deployment.yaml
kubectl apply -f K8S/backend_service.yaml

# انتظر حتى يصبح Backend جاهزاً
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s

# 4. Nginx Proxy
kubectl apply -f K8S/proxy_deployment.yaml
kubectl apply -f K8S/proxy_nodeport.yaml
```

### 5. التحقق من النشر

```bash
# عرض جميع الموارد
kubectl get all

# عرض Pods
kubectl get pods

# عرض Services
kubectl get services

# عرض PV و PVC
kubectl get pv,pvc

# عرض Secrets
kubectl get secrets
```

### 6. الوصول إلى التطبيق

```bash
# الحصول على URL (Minikube)
minikube service nginx-service --url

# أو استخدام NodePort مباشرة
curl -k https://$(minikube ip):30443/
curl -k https://$(minikube ip):30443/blogs
```

### 7. فحص السجلات والتصحيح

```bash
# سجلات Backend
kubectl logs -l app=backend -f

# سجلات MySQL
kubectl logs -l app=mysql -f

# سجلات Nginx
kubectl logs -l app=nginx -f

# الدخول إلى Pod
kubectl exec -it <pod-name> -- /bin/sh

# وصف Pod
kubectl describe pod <pod-name>
```

### 8. التحديث والصيانة

```bash
# إعادة تشغيل Deployment
kubectl rollout restart deployment/backend-deployment

# التحقق من حالة Rollout
kubectl rollout status deployment/backend-deployment

# التراجع عن تحديث
kubectl rollout undo deployment/backend-deployment

# توسيع/تقليص عدد النسخ
kubectl scale deployment/backend-deployment --replicas=3
```

### 9. التنظيف

```bash
# حذف جميع الموارد
kubectl delete -f K8S/

# أو حذف كل شيء في namespace
kubectl delete all --all

# حذف PV و PVC
kubectl delete pv,pvc --all
```

---

## 🧪 الاختبار

### اختبار API Endpoints

```bash
# الصفحة الرئيسية
curl -k https://localhost/

# فحص الصحة
curl -k https://localhost/health

# قائمة المدونات
curl -k https://localhost/blogs | jq

# إضافة مدونة
curl -k -X POST https://localhost/blogs \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Docker and Kubernetes Guide",
    "content": "Learn how to deploy applications",
    "author": "DevOps Engineer"
  }' | jq
```

---

## 🔒 الأمان

- يستخدم Nginx شهادة SSL ذاتية التوقيع (للإنتاج استخدم Let's Encrypt)
- كلمات المرور مخزنة في Secrets
- الاتصالات بين الخدمات داخلية فقط
- Backend و MySQL غير معرضين للخارج مباشرة

---

## 🛠️ استكشاف الأخطاء

### المشكلة: Backend لا يتصل بقاعدة البيانات

```bash
# تحقق من حالة MySQL
kubectl get pods -l app=mysql

# فحص سجلات MySQL
kubectl logs -l app=mysql

# تحقق من اتصال الشبكة
kubectl exec -it <backend-pod> -- ping mysql-service
```

### المشكلة: Nginx يعرض 502 Bad Gateway

```bash
# تحقق من حالة Backend
kubectl get pods -l app=backend

# اختبر Backend مباشرة
kubectl port-forward svc/backend-service 8080:8080
curl http://localhost:8080/health
```

### المشكلة: PVC في حالة Pending

```bash
# تحقق من PV
kubectl get pv

# وصف PVC
kubectl describe pvc db-data-pvc

# للتطوير المحلي، قد تحتاج إلى استخدام storageClassName مختلف
```

---

## 📊 المراقبة

### عرض استخدام الموارد

```bash
# استخدام الموارد للـ Pods
kubectl top pods

# استخدام الموارد للـ Nodes
kubectl top nodes

# Dashboard (Minikube)
minikube dashboard
```

---

## 🎯 الميزات

- ✅ Multi-stage Docker builds لتقليل حجم الصور
- ✅ Health checks لجميع الخدمات
- ✅ Persistent storage لقاعدة البيانات
- ✅ HTTPS مع شهادات SSL
- ✅ Secret management لكلمات المرور
- ✅ Resource limits و requests
- ✅ High availability مع replicas متعددة
- ✅ Auto-restart في حالة الفشل

---

## 📝 ملاحظات

- للإنتاج، استخدم شهادات SSL حقيقية من Let's Encrypt
- قم بتغيير كلمات المرور الافتراضية
- استخدم LoadBalancer أو Ingress Controller للإنتاج بدلاً من NodePort
- قم بإعداد backup منتظم لقاعدة البيانات
- استخدم CI/CD pipeline للنشر التلقائي

---

## 📚 موارد إضافية

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Go Documentation](https://golang.org/doc/)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

## 👨‍💻 المساهمة

المساهمات مرحب بها! يرجى:
1. Fork المشروع
2. إنشاء branch جديد
3. Commit التغييرات
4. Push إلى branch
5. فتح Pull Request

---

## 📄 الترخيص

MIT License - استخدم بحرية!
