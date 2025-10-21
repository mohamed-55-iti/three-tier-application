#!/bin/bash

echo "=========================================="
echo "Testing Three-Tier Application"
echo "=========================================="
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

echo "1. Docker Compose Backend:"
curl -s http://localhost:8080 | head -c 100
echo ""

echo "2. Docker Compose Nginx:"
curl -sk https://localhost | head -c 100
echo ""

echo "3. Kubernetes Nginx:"
curl -sk https://localhost:30443 | head -c 100
echo ""

echo "4. All Services:"
echo "   Docker: http://${SERVER_IP}:8080"
echo "   Docker: https://${SERVER_IP}"
echo "   K8s:    https://${SERVER_IP}:30443"
echo ""
