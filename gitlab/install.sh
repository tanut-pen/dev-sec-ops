#!/usr/bin/env bash
set -euo pipefail

helm repo add gitlab https://charts.gitlab.io/ --force-update
helm repo update

helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=example.com \
  --set global.hosts.externalIP=10.10.10.10 \
  --set certmanager-issuer.email=me@example.com \
  --namespace gitlab \
  --create-namespace