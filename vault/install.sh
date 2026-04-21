helm upgrade --install vault hashicorp/vault \
  --namespace vault --create-namespace -f vault-values.yaml