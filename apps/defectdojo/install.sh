#!/usr/bin/env bash
set -euo pipefail

helm repo add defectdojo https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts --force-update
helm repo update

helm upgrade --install defectdojo defectdojo/defectdojo \
  --namespace defectdojo \
  --create-namespace \
  -f defectdojo-values.yaml \
  --set createSecret=true \
  --set createValkeySecret=true \
  --set createPostgresqlSecret=true \
  --set django.ingress.enabled=false