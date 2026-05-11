#!/usr/bin/env bash
set -euo pipefail

helm repo add istio https://istio-release.storage.googleapis.com/charts --force-update
helm repo update

helm upgrade --install istio-base istio/base \
  --namespace istio-system \
  --create-namespace \
  --wait \
  -f base-values.yaml

helm upgrade --install istiod istio/istiod \
  --namespace istio-system \
  --wait \
  -f istiod-values.yaml

helm upgrade --install istio-ingress istio/gateway \
  --namespace istio-ingress \
  --create-namespace \
  -f gateway-values.yaml
