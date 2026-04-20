helm upgrade --install jenkins jenkins/jenkins -n jenkins --create-namespace -f values.yaml

zVNaZPZRM3fH8zLOZv2nub

helm show values jenkins/jenkins > values.yaml