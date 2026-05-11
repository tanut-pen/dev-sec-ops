#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo update

helm upgrade --install grafana-alloy grafana/alloy \
  --namespace grafana-alloy \
  --create-namespace \
  -f values.yaml
