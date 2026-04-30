#!/usr/bin/env bash
set -euo pipefail

helm repo add jenkins https://charts.jenkins.io --force-update
helm repo update

helm upgrade --install jenkins jenkins/jenkins \
  --namespace jenkins \
  --create-namespace \
  -f jenkins-values.yaml