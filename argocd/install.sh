#!/usr/bin/env bash
set -euo pipefail

helm repo add argo https://argoproj.github.io/argo-helm --force-update
helm repo update

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f values-argocd.yaml

helm upgrade --install argo-rollouts argo/argo-rollouts \
  --namespace argo-rollouts \
  --create-namespace \
  -f values-rollouts.yaml
