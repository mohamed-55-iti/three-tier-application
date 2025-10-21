.PHONY: help build up down logs test clean k8s-deploy k8s-clean

# متغيرات
DOCKER_USERNAME ?= your-username
BACKEND_IMAGE = $(DOCKER_USERNAME)/three-tier-backend:latest
NGINX_IMAGE = $(DOCKER_USERNAME)/three-tier-nginx:latest

help: ## عرض قائمة الأوامر المتاحة
	@echo "الأوامر المتاحة:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

# ========================================
# Docker Compose Commands
# ========================================

build: ## بناء جميع الصور
	docker-compose build

up: ## تشغيل التطبيق
	docker-compose up -d

down: ## إيقاف التطبيق
	docker-compose down

logs: ## عرض السجلات
	docker-compose logs -f

restart: ## إعادة تشغيل التطبيق
	docker-compose restart

ps: ## عرض حالة الحاويات
	docker-compose ps

test: ## اختبار API
	@echo "Testing API endpoints..."
	@curl -k https://localhost/ || true
	@echo "\n"
	@curl -k https://localhost/health || true
	@echo "\n"
	@curl -k https://localhost/blogs || true

clean: down ## تنظيف كامل مع حذف البيانات
	docker-compose down -v
	docker system prune -f

# ========================================
# Docker Build & Push Commands
# ========================================

docker-build: ## بناء صور Docker
	docker build -t $(BACKEND_IMAGE) ./backend
	docker build -t $(NGINX_IMAGE) ./nginx

docker-push: ## رفع الصور إلى Docker Hub
	docker push $(BACKEND_IMAGE)
	docker push $(NGINX_IMAGE)

docker-all: docker-build docker-push ## بناء ورفع الصور

# ========================================
# Kubernetes Commands
# ========================================

k8s-deploy: ## نشر التطبيق على Kubernetes
	@echo "Deploying to Kubernetes..."
	kubectl apply -f K8S/db-secret.yaml
	kubectl apply -f K8S/db-data-pv.yaml
	kubectl apply -f K8S/db-data-pvc.yaml
	kubectl apply -f K8S/database_deployment.yaml
	kubectl apply -f K8S/db-service.yaml
	@echo "Waiting for MySQL to be ready..."
	kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s || true
	kubectl apply -f K8S/backend_deployment.yaml
	kubectl apply -f K8S/backend_service.yaml
	@echo "Waiting for Backend to be ready..."
	kubectl wait --for=condition=ready pod -l app=backend --timeout=120s || true
	kubectl apply -f K8S/proxy_deployment.yaml
	kubectl apply -f K8S/proxy_nodeport.yaml
	@echo "✅ Deployment complete!"

k8s-status: ## عرض حالة الموارد في Kubernetes
	@echo "=== Pods ==="
	kubectl get pods
	@echo "\n=== Services ==="
	kubectl get services
	@echo "\n=== PV & PVC ==="
	kubectl get pv,pvc

k8s-logs: ## عرض سجلات جميع الخدمات
	@echo "=== Backend Logs ==="
	kubectl logs -l app=backend --tail=20
	@echo "\n=== MySQL Logs ==="
	kubectl logs -l app=mysql --tail=20
	@echo "\n=== Nginx Logs ==="
	kubectl logs -l app=nginx --tail=20

k8s-clean: ## حذف جميع موارد Kubernetes
	kubectl delete -f K8S/ || true
	kubectl delete pv,pvc --all || true

k8s-restart: ## إعادة تشغيل deployments
	kubectl rollout restart deployment/backend-deployment
	kubectl rollout restart deployment/nginx-deployment

# ========================================
# Minikube Commands
# ========================================

minikube-start: ## بدء Minikube
	minikube start --driver=docker

minikube-stop: ## إيقاف Minikube
	minikube stop

minikube-delete: ## حذف Minikube cluster
	minikube delete

minikube-url: ## الحصول على URL للوصول إلى التطبيق
	@echo "Application URL:"
	@minikube service nginx-service --url

minikube-dashboard: ## فتح Kubernetes dashboard
	minikube dashboard

# ========================================
# Development Commands
# ========================================

dev-setup: ## إعداد بيئة التطوير
	@echo "Setting up development environment..."
	@test -f db-password.txt || echo "MySecurePassword123!" > db-password.txt
	@echo "✅ Development environment ready!"

dev-backend: ## تشغيل Backend محلياً
	cd backend && go run main.go

dev-test: ## اختبار Backend محلياً
	cd backend && go test -v ./...

# ========================================
# Utility Commands
# ========================================

secret-encode: ## تشفير كلمة مرور إلى Base64
	@read -p "Enter password: " password; \
	echo -n "$$password" | base64

init: dev-setup docker-build up ## تهيئة المشروع للمرة الأولى
	@echo "🎉 Project initialized successfully!"
	@echo "Access the application at: https://localhost"
