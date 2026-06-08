#!/usr/bin/env bash
set -euo pipefail

# NOTE: Bitnami MySQL images were removed from Docker Hub free tier after Aug 2025.
# Using plain kubectl manifest with official mysql:8.0 image instead.

kubectl create namespace dongtai --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f mysql.yaml

echo ""
echo "Waiting for MySQL to be ready..."
kubectl rollout status statefulset/mysql -n dongtai --timeout=120s

echo ""
echo "✅ MySQL is up."
echo "   Internal:  mysql.dongtai.svc.cluster.local:3306"
echo "   NodePort:  <node-ip>:30306"
echo "   User/Pass: root / dongtai-iast"
echo "   Database:  dongtai_webapi"
