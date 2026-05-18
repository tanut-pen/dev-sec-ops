helm repo add dongtai https://charts.dongtai.io/iast
helm repo update


helm install project --create-namespace -n dongtai dongtai/dongtai-iast \
--set storage.persistentVolumeClaim=null