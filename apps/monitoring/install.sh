#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Add repos
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo update

echo "Deploying Grafana/Prometheus (kube-prometheus-stack)..."
helm upgrade --install grafana prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  -f "${SCRIPT_DIR}/values-grafana.yaml"

echo "Deploying Grafana Alloy..."
helm upgrade --install grafana-alloy grafana/alloy \
  --namespace monitoring \
  --create-namespace \
  -f "${SCRIPT_DIR}/alloy-values.yaml"

echo "Deploying Grafana Tempo..."
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --create-namespace \
  -f "${SCRIPT_DIR}/tempo-values.yaml"

echo "Monitoring stack deployed successfully in namespace monitoring."
