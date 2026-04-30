#!/usr/bin/env bash
set -euo pipefail

helm repo add harbor https://helm.goharbor.io --force-update
helm repo update

helm upgrade --install my-harbor harbor/harbor \
  --namespace harbor \
  --create-namespace \
  -f harbor-local.yaml