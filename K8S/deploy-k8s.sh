#!/bin/bash

set -e

echo "=========================================="
echo "Deploying Three-Tier App to Kubernetes"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

cd /root/three-tier-app/K8S

# Step 1: Create Secret
echo -e "${YELLOW}Step 1: Creating Secret...${NC}"
kubectl apply -f db-secret.yaml
echo -e "${GREEN}✓ Secret created${NC}"
echo ""

# Step 2: Create PV and PVC
echo -e "${YELLOW}Step 2: Creating Persistent Volume...${NC}"
kubectl apply -f db-data-pv.yaml
kubectl apply -f db-data-pvc.yaml
echo -e "${GREEN}✓ PV and PVC created${NC}"
echo ""

# Step 3: Deploy Database
echo -e "${YELLOW}Step 3: Deploying Database...${NC}"
kubectl apply -f database_deployment.yaml
kubectl apply -f db-service.yaml
echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=mysql --timeout=120s || {
    echo -e "${RED}✗ Database failed to start${NC}"
    kubectl get pods -l app=mysql
    kubectl logs -l app=mysql --tail=50
    exit 1
}
echo -e "${GREEN}✓ Database ready${NC}"
echo ""

# Step 4: Deploy Backend
echo -e "${YELLOW}Step 4: Deploying Backend...${NC}"
kubectl apply -f backend_deployment.yaml
kubectl apply -f backend_service.yaml
echo "Waiting for backend to be ready..."
kubectl wait --for=condition=ready pod -l app=backend --timeout=120s || {
    echo -e "${RED}✗ Backend failed to start${NC}"
    kubectl get pods -l app=backend
    kubectl logs -l app=backend --tail=50
    exit 1
}
echo -e "${GREEN}✓ Backend ready${NC}"
echo ""

# Step 5: Deploy Nginx Proxy
echo -e "${YELLOW}Step 5: Deploying Nginx Proxy...${NC}"
kubectl apply -f proxy_deployment.yaml
kubectl apply -f proxy_nodeport.yaml
echo "Waiting for nginx to be ready..."
kubectl wait --for=condition=ready pod -l app=nginx --timeout=60s || {
    echo -e "${RED}✗ Nginx failed to start${NC}"
    kubectl get pods -l app=nginx
    kubectl logs -l app=nginx --tail=50
    exit 1
}
echo -e "${GREEN}✓ Nginx ready${NC}"
echo ""

# Display status
echo "=========================================="
echo "Deployment Summary"
echo "=========================================="
echo ""
kubectl get pods
echo ""
kubectl get svc
echo ""

# Get NodePorts
NODE_PORT_HTTP=$(kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}')
NODE_PORT_HTTPS=$(kubectl get svc nginx -o jsonpath='{.spec.ports[1].nodePort}')
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "=========================================="
echo "Access URLs"
echo "=========================================="
echo ""
echo -e "${GREEN}HTTP:${NC}  http://${SERVER_IP}:${NODE_PORT_HTTP}"
echo -e "${GREEN}HTTPS:${NC} https://${SERVER_IP}:${NODE_PORT_HTTPS}"
echo ""
echo "Note: HTTPS uses self-signed certificate"
echo ""

# Test connectivity
echo "=========================================="
echo "Testing Application"
echo "=========================================="
echo ""
echo "Testing HTTPS endpoint..."
RESPONSE=$(curl -k -s https://localhost:${NODE_PORT_HTTPS} || echo "Failed")
if [[ $RESPONSE == *"Blog post"* ]]; then
    echo -e "${GREEN}✓ Application is working!${NC}"
    echo "Response: $RESPONSE"
else
    echo -e "${RED}✗ Application test failed${NC}"
    echo "Response: $RESPONSE"
fi
echo ""

echo "=========================================="
echo "Deployment Complete! 🎉"
echo "=========================================="
