#!/usr/bin/env bash
set -euo pipefail

helm repo add defectdojo https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts --force-update
helm repo update

helm upgrade --install defectdojo defectdojo/defectdojo \
  --namespace defectdojo \
  --create-namespace \
  -f values-dojo.yaml \
  --set createSecret=true \
  --set createValkeySecret=true \
  --set createPostgresqlSecret=true \
  --set django.ingress.enabled=false

kubectl set env deployment/defectdojo-django \
  DD_CSRF_COOKIE_SECURE=True \
  DD_SESSION_COOKIE_SECURE=True \
  DD_CSRF_TRUSTED_ORIGINS=http://defectdojo.local \
  -n defectdojo