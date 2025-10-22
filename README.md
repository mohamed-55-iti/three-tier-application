# Three-Tier Application: Backend | Database | Proxy

A production-ready three-tier web application deployed using Docker Compose and Kubernetes.

## 🏗️ Architecture

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       │ HTTPS
       ▼
┌─────────────┐
│    Nginx    │ (Reverse Proxy)
│   (HTTPS)   │
└──────┬──────┘
       │
       │ HTTP
       ▼
┌─────────────┐
│   Backend   │ (Go API)
│  (Port 8000)│
└──────┬──────┘
       │
       │ MySQL Protocol
       ▼
┌─────────────┐
│   MySQL     │ (Database)
│  (Port 3306)│
└─────────────┘
```

## 🚀 Features

- **Backend API**: Go application serving REST API for blog posts
- **Database**: MySQL 8.0 with persistent storage
- **Reverse Proxy**: Nginx with HTTPS (self-signed certificate)
- **Multi-stage Docker builds**: Optimized image sizes
- **Health checks**: All services monitored
- **Secrets management**: Secure credential handling
- **Persistent storage**: Data survives container restarts
- **Auto-restart**: Services automatically start after reboot

## 📋 Prerequisites

### For Docker Compose:
- Docker Engine 20.10+
- Docker Compose 2.0+

### For Kubernetes:
- Kubernetes cluster 1.24+
- kubectl configured
- 2 CPU cores and 4GB RAM minimum

## 🐳 Docker Compose Deployment

### Quick Start

```bash
# Clone the repository
git clone <your-repo-url>
cd three-tier-app

# Create password file
echo "MySecurePassword123!" > db-password.txt

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### Access URLs

- **Backend API**: http://localhost:8080
- **Nginx (HTTPS)**: https://localhost
- **Nginx (HTTP)**: http://localhost (redirects to HTTPS)

### Stop Services

```bash
docker compose down
```

## ☸️ Kubernetes Deployment

### Prerequisites

Ensure Docker images are built and available on all nodes:

```bash
# Build images
docker compose build

# Save images
docker save three-tier-app-backend:latest -o backend.tar
docker save three-tier-app-nginx:latest -o nginx.tar

# Load on each node
docker load -i backend.tar
docker load -i nginx.tar

# Or use containerd
ctr -n k8s.io images import backend.tar
ctr -n k8s.io images import nginx.tar
```

### Deploy to Kubernetes

```bash
cd K8S

# Create secret
kubectl apply -f db-secret.yaml

# Create persistent storage
kubectl apply -f db-data-pv.yaml
kubectl apply -f db-data-pvc.yaml

# Deploy database
kubectl apply -f database_deployment.yaml
kubectl apply -f db-service.yaml

# Wait for database
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s

# Deploy backend
kubectl apply -f backend_deployment.yaml
kubectl apply -f backend_service.yaml

# Wait for backend
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s

# Deploy nginx proxy
kubectl apply -f proxy_deployment.yaml
kubectl apply -f proxy_nodeport.yaml

# Check status
kubectl get all
```

### Access URLs

- **HTTP**: http://<node-ip>:30080
- **HTTPS**: https://<node-ip>:30443

### Automated Deployment

Use the provided script:

```bash
./startup-all.sh
```

## 🗂️ Project Structure

```
three-tier-app/
├── backend/
│   ├── Dockerfile          # Multi-stage build for Go app
│   ├── main.go            # Go REST API application
│   ├── go.mod             # Go dependencies
│   └── go.sum
├── nginx/
│   ├── Dockerfile         # Nginx with SSL generation
│   ├── nginx.conf         # Nginx configuration
│   └── generate-ssl.sh    # SSL certificate generator
├── K8S/
│   ├── db-secret.yaml           # Database credentials
│   ├── db-data-pv.yaml          # Persistent Volume
│   ├── db-data-pvc.yaml         # Persistent Volume Claim
│   ├── database_deployment.yaml # MySQL deployment
│   ├── db-service.yaml          # MySQL service
│   ├── backend_deployment.yaml  # Backend deployment
│   ├── backend_service.yaml     # Backend service
│   ├── proxy_deployment.yaml    # Nginx deployment
│   └── proxy_nodeport.yaml      # Nginx NodePort service
├── docker-compose.yaml    # Docker Compose configuration
├── startup-all.sh         # Start all services
├── stop-all.sh           # Stop all services
├── test-all.sh           # Test all endpoints
└── README.md             # This file
```

## 🔧 Configuration

### Database Credentials

For Docker Compose, create `db-password.txt`:

```bash
echo "YourSecurePassword" > db-password.txt
```

For Kubernetes, edit `K8S/db-secret.yaml`:

```yaml
stringData:
  db-password: "YourSecurePassword"
```

### Environment Variables

Backend supports these environment variables:

- `DB_HOST`: Database hostname (default: db)
- `DB_PORT`: Database port (default: 3306)
- `DB_USER`: Database user (default: root)
- `DB_NAME`: Database name (default: example)
- `PORT`: Backend API port (default: 8000)

## 🧪 Testing

### Test All Services

```bash
./test-all.sh
```

### Manual Testing

```bash
# Test Docker Compose backend
curl http://localhost:8080

# Test Docker Compose nginx
curl -k https://localhost

# Test Kubernetes
curl -k https://<node-ip>:30443
```

Expected response:
```json
["Blog post #0","Blog post #1","Blog post #2","Blog post #3","Blog post #4"]
```

## 📊 Monitoring

### Docker Compose

```bash
# View all services
docker compose ps

# View logs
docker compose logs -f [service-name]

# View resource usage
docker stats
```

### Kubernetes

```bash
# View all resources
kubectl get all

# View pod logs
kubectl logs -f <pod-name>

# View pod details
kubectl describe pod <pod-name>

# View events
kubectl get events --sort-by='.lastTimestamp'
```

## 🔒 Security Notes

- The application uses **self-signed SSL certificates** for HTTPS
- Database passwords are stored as **Kubernetes Secrets** or **Docker Secrets**
- Never commit `db-password.txt` to version control
- In production, use proper certificate authorities for SSL
- Consider using external secret management (HashiCorp Vault, AWS Secrets Manager, etc.)

## 🐛 Troubleshooting

### Docker Compose Issues

```bash
# Restart services
docker compose restart

# Rebuild images
docker compose up -d --build

# View detailed logs
docker compose logs -f backend
```

### Kubernetes Issues

```bash
# Check pod status
kubectl get pods

# Check pod logs
kubectl logs <pod-name>

# Describe pod for events
kubectl describe pod <pod-name>

# Check if images are available
kubectl describe pod <pod-name> | grep -A 5 "Image"

# Restart deployment
kubectl rollout restart deployment/<deployment-name>
```

### Common Issues

1. **Backend CrashLoopBackOff**
   - Check database is ready: `kubectl get pods -l app=mysql`
   - Verify secret exists: `kubectl get secret db-secret`
   - Check logs: `kubectl logs -l app=backend`

2. **ImagePullBackOff**
   - Ensure images are loaded on all nodes
   - Use `imagePullPolicy: Never` for local images
   - Verify image name matches exactly

3. **502 Bad Gateway**
   - Backend not ready yet (wait for health checks)
   - Check backend logs: `kubectl logs -l app=backend`
   - Verify backend service: `kubectl get svc backend`

## 🔄 Backup and Restore

### Backup

```bash
# Backup Kubernetes resources
kubectl get all -o yaml > backup.yaml

# Backup database
kubectl exec <mysql-pod> -- mysqldump -u root -p<password> example > backup.sql
```

### Restore

```bash
# Restore Kubernetes resources
kubectl apply -f backup.yaml

# Restore database
kubectl exec -i <mysql-pod> -- mysql -u root -p<password> example < backup.sql
```

## 📝 Development

### Build and Test Locally

```bash
# Build backend
cd backend
go build -o main .

# Test backend
./main

# Build Docker images
docker compose build

# Run locally
docker compose up
```

### Make Changes

1. Edit source code
2. Rebuild images: `docker compose build`
3. Restart services: `docker compose up -d`
4. Test changes: `./test-all.sh`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- Mohamed Khaled Ahmed

## 🙏 Acknowledgments

- Go community for excellent libraries
- Docker and Kubernetes documentation
- Nginx for robust reverse proxy capabilities

## 📞 Support

For issues and questions:
- Create an issue in the GitHub repository
- Email: mohamedkhaledramy99@gmail.com

---

**Made with ❤️ for learning and production deployments**
