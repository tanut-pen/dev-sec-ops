#!/bin/bash

set -e 

echo "=============================================================="
echo "install envoy gateway..."

helm upgrade -i eg oci://docker.io/envoyproxy/gateway-helm \
  --version v1.8.1 \
  --namespace envoy-gateway-system \
  --create-namespace \
  -f https://raw.githubusercontent.com/envoyproxy/ai-gateway/main/manifests/envoy-gateway-values.yaml

kubectl wait --timeout=2m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available

echo "=============================================================="
echo "install envoy gateway completed"

echo "=============================================================="
echo "install envoy ai gateway crds..."

helm upgrade -i aieg-crd oci://docker.io/envoyproxy/ai-gateway-crds-helm \
  --version v1.1.0 \
  --namespace envoy-ai-gateway-system \
  --create-namespace


echo "=============================================================="
echo "install envoy ai gateway crds completed"

echo "=============================================================="
echo "Install AI Gateway Resources"

helm upgrade -i aieg oci://docker.io/envoyproxy/ai-gateway-helm \
  --version v1.1.0 \
  --namespace envoy-ai-gateway-system \
  --create-namespace

kubectl wait --timeout=2m -n envoy-ai-gateway-system deployment/ai-gateway-controller --for=condition=Available