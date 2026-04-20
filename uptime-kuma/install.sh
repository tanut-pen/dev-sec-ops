#!/bin/bash
# Add uptime-kuma helm repo
helm repo add uptime-kuma https://helm.irsigler.cloud
helm repo update

# Install / upgrade uptime-kuma
helm upgrade --install uptime-kuma uptime-kuma/uptime-kuma \
  --namespace monitoring \
  --create-namespace \
  -f values.yaml

# Show default values (run once to generate values.yaml)
# helm show values uptime-kuma/uptime-kuma > values.yaml
