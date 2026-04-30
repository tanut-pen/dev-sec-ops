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

# Enforce local HTTP cookie/CSRF settings on the running deployment.
# This also corrects older installs where these were set to True.
kubectl -n defectdojo set env deployment/defectdojo-django \
  DD_CSRF_COOKIE_SECURE=False \
  DD_SESSION_COOKIE_SECURE=False \
  DD_CSRF_TRUSTED_ORIGINS=http://defectdojo.local