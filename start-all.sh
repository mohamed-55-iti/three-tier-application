#!/bin/bash

# Startup script for Three-Tier Application
# Run this after system restart

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Starting Three-Tier Application"
echo "=========================================="
echo ""

# 1. Start Docker Compose Application
echo -e "${YELLOW}1. Starting Docker Compose Application...${NC}"
cd /root/three-tier-app
docker compose up -d
echo -e "${GREEN}✓ Docker Compose started${NC}"
echo ""

# 2. Wait for Kubernetes to be ready
echo -e "${YELLOW}2. Waiting for Kubernetes...${NC}"
timeout=60
while ! kubectl get nodes &>/dev/null; do
    echo "Waiting for kubectl..."
    sleep 2
    timeout=$((timeout - 2))
    if [ $timeout -le 0 ]; then
        echo "Timeout waiting for Kubernetes"
        exit 1
    fi
done
echo -e "${GREEN}✓ Kubernetes is ready${NC}"
echo ""

# 3. Check if K8s application is running
echo -e "${YELLOW}3. Checking Kubernetes Application...${NC}"
cd /root/three-tier-app/K8S

PODS_RUNNING=$(kubectl get pods --no-headers 2>/dev/null | wc -l)

if [ "$PODS_RUNNING" -eq 0 ]; then
    echo "No pods found. Deploying application..."
    
    # Deploy in order
    kubectl apply -f db-secret.yaml
    kubectl apply -f db-data-pv.yaml
    kubectl apply -f db-data-pvc.yaml
    kubectl apply -f database_deployment.yaml
    kubectl apply -f db-service.yaml
    
    echo "Waiting for MySQL..."
    kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s
    
    kubectl apply -f backend_deployment.yaml
    kubectl apply -f backend_service.yaml
    
    echo "Waiting for Backend..."
    kubectl wait --for=condition=ready pod -l app=backend --timeout=120s
    
    kubectl apply -f proxy_deployment.yaml
    kubectl apply -f proxy_nodeport.yaml
    
    echo -e "${GREEN}✓ Kubernetes application deployed${NC}"
else
    echo -e "${GREEN}✓ Kubernetes application already running ($PODS_RUNNING pods)${NC}"
fi
echo ""

# 4. Display status
echo "=========================================="
echo "Application Status"
echo "=========================================="
echo ""

echo -e "${YELLOW}Docker Compose:${NC}"
docker compose ps
echo ""

echo -e "${YELLOW}Kubernetes:${NC}"
kubectl get pods
echo ""
kubectl get svc
echo ""

# 5. Get access URLs
SERVER_IP=$(hostname -I | awk '{print $1}')
K8S_HTTP_PORT=$(kubectl get svc nginx-service -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A")
K8S_HTTPS_PORT=$(kubectl get svc nginx-service -o jsonpath='{.spec.ports[1].nodePort}' 2>/dev/null || echo "N/A")

echo "=========================================="
echo "Access URLs"
echo "=========================================="
echo ""
echo -e "${GREEN}Docker Compose:${NC}"
echo "  Backend:  http://${SERVER_IP}:8080"
echo "  Nginx:    https://${SERVER_IP}"
echo ""
echo -e "${GREEN}Kubernetes:${NC}"
echo "  HTTP:     http://${SERVER_IP}:${K8S_HTTP_PORT}"
echo "  HTTPS:    https://${SERVER_IP}:${K8S_HTTPS_PORT}"
echo ""

echo "=========================================="
echo "Startup Complete! 🎉"
echo "=========================================="
