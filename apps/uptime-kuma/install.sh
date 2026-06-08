#!/usr/bin/env bash
set -euo pipefail

helm repo add uptime-kuma https://helm.irsigler.cloud --force-update
helm repo update

helm upgrade --install uptime-kuma uptime-kuma/uptime-kuma \
  --namespace monitoring \
  --create-namespace \
  -f values.yaml
