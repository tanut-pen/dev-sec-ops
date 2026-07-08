#!/usr/bin/env bash
set -euo pipefail

helm repo add grafana https://grafana.github.io/helm-charts --force-update
helm repo update

helm upgrade --install loki grafana/loki \
  --namespace loki \
  --create-namespace \
  -f loki-values.yaml
