helm repo add harbor https://helm.goharbor.io
helm repo update
helm install my-harbor harbor/harbor -f harbor-local.yaml -n harbor --create-namespace
helm upgrade --install my-harbor harbor/harbor -f harbor-local.yaml -n harbor

helm show values harbor/harbor > harbor-values.yaml