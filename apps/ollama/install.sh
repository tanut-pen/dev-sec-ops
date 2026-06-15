#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl create namespace ollama --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k "${SCRIPT_DIR}"
echo ""
echo "Ollama deployed. The qwen3:0.6b model will be pulled automatically on first start."
echo "API endpoint: http://ollama.ollama.svc.cluster.local:11434"
echo "NodePort:     http://localhost:30435"
