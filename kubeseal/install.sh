#!/usr/bin/env bash
set -euo pipefail

helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets --force-update
helm repo update

helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --create-namespace
