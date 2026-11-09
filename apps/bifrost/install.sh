#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

helm repo add bifrost https://maximhq.github.io/bifrost/helm-charts --force-update
helm repo update

helm upgrade --install bifrost bifrost/bifrost \
  --namespace bifrost \
  --create-namespace \
  -f "${SCRIPT_DIR}/bifrost-values.yaml"

