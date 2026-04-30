#!/usr/bin/env bash
set -euo pipefail

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts --force-update
helm repo update

helm upgrade --install grafana prometheus-community/kube-prometheus-stack \
  --namespace grafana \
  --create-namespace \
  -f values-grafana.yaml
