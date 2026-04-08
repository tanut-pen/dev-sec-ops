helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install grafana prometheus-community/kube-prometheus-stack \
  -n grafana \
  --create-namespace \
  -f values-grafana.yaml
