#!/usr/bin/env bash
set -euo pipefail

helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
helm repo update

helm upgrade --install postgres bitnami/postgresql \
  --namespace postgres \
  --create-namespace \
  -f values.yaml
