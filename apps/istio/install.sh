#install
istioctl install --set profile=demo -y

#label the demo namespace for automatic sidecar injection
kubectl label namespace demo istio-injection=enabled
kubectl label namespace kong istio-injection=enabled

#uninstall
istioctl uninstall --purge -y
kubectl label namespace demo istio-injection-