helm repo add robusta https://robusta-charts.storage.googleapis.com
helm repo update
helm install robusta robusta/robusta -f robusta-values.yaml
helm show values robusta/robusta > robusta-values.yaml