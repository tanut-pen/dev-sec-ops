#!/usr/bin/env bash
set -euo pipefail

# Install Sealed Secrets via Helm
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
helm install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --create-namespace
