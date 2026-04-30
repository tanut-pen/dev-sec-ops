#!/usr/bin/env bash
set -euo pipefail

helm repo add portainer https://portainer.github.io/k8s/ --force-update
helm repo update

helm upgrade --install portainer portainer/portainer \
  --namespace portainer \
  --create-namespace \
  --set service.type=NodePort \
  -f values.yaml