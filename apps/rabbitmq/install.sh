#!/usr/bin/env bash
set -euo pipefail

helm repo add bitnami https://charts.bitnami.com/bitnami --force-update
helm repo update

helm upgrade --install rabbitmq bitnami/rabbitmq \
  --namespace rabbitmq \
  --create-namespace \
  -f rabbitmq-values.yaml
