#!/usr/bin/env bash
set -euo pipefail

helm repo add hashicorp https://helm.releases.hashicorp.com --force-update
helm repo update

helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  -f vault-values.yaml