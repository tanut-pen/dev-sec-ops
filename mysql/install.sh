#!/usr/bin/env bash
set -euo pipefail

helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
helm repo update

helm upgrade --install mysql bitnami/mysql \
  --namespace dongtai \
  --create-namespace \
  -f values.yaml
