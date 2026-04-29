#helm uninstall sonarqube -n security-tools -f values-sonar.yaml

helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
helm upgrade --install -n sonarqube sonarqube sonarqube/sonarqube -f sonarqube-values.yaml --create-namespace