#!/usr/bin/env bash
set -euo pipefail

helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube --force-update
helm repo update

helm upgrade --install sonarqube sonarqube/sonarqube \
  --namespace sonarqube \
  --create-namespace \
  -f sonarqube-values.yaml