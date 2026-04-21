#!/bin/bash
# Add Kong helm repo
helm repo add kong https://charts.konghq.com
helm repo update

# Install / upgrade Kong Gateway (DB-less mode)
helm upgrade --install kong kong/kong \
  --namespace kong \
  --create-namespace \
  -f kong-values.yaml

# Show default values (run once to regenerate values.yaml)
# helm show values kong/kong > values.yaml
