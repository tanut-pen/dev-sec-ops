#!/usr/bin/env bash
set -euo pipefail

helm repo add kong https://charts.konghq.com --force-update
helm repo update

helm upgrade --install kong kong/kong \
  --namespace kong \
  --create-namespace \
  -f kong-values.yaml
