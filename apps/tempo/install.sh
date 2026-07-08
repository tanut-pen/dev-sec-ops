#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo update

helm upgrade --install tempo grafana/tempo \
  --namespace tempo \
  --create-namespace \
  -f tempo-values.yaml
