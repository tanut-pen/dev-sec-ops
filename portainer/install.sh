helm repo add portainer https://portainer.github.io/k8s/
helm repo update
helm install --create-namespace -n portainer portainer portainer/portainer \
  --set service.type=NodePort -f values.yaml
# helm show values portainer/portainer > values.yaml

# kubectl create secret generic portainer-admin-password \
#        --from-literal=password=admin@portainer \
#        -n portainer