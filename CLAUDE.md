# CLAUDE.md — Token & Credential Reference

> ⚠️ **Do NOT commit real credentials here in a shared/production repo.**
> This file is for local lab use only.

## Service Credentials

| Service | URL | Username | Password / Token |
|---------|-----|----------|-----------------|
| Jenkins | http://localhost:30003 | admin | admin |
| SonarQube | http://sonarqube.local | admin | admin |
| Harbor | http://localhost:30002 | admin | Harbor12345 |
| DefectDojo | http://localhost:30001 | admin | *(see first-run output)* |
| Argo CD | http://localhost:30004 | admin | *(see `argocd admin initial-password`)* |
| Grafana | http://localhost:30005 | admin | prom-operator |
| Uptime Kuma | http://localhost:30006 | *(set on first login)* | *(set on first login)* |
| Vault | — | root | *(see init output)* |

## Jenkins Credentials (stored in Jenkins)

| ID | Type | Usage |
|----|------|-------|
| `harbor-credentials` | Username/Password | Push images to Harbor |
| `defectdojo-api-token` | Secret text | Import Trivy reports to DefectDojo |
| `sonar` | Secret text | SonarQube analysis token |

## Helm Repos Added

```bash
helm repo add jenkins      https://charts.jenkins.io
helm repo add sonarqube    https://SonarSource.github.io/helm-chart-sonarqube
helm repo add harbor       https://helm.goharbor.io
helm repo add defectdojo   https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts
helm repo add argo          https://argoproj.github.io/argo-helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add hashicorp    https://helm.releases.hashicorp.com
helm repo add uptime-kuma  https://helm.irsigler.cloud
helm repo update
```

## Notes

- Jenkins `install.sh` line 3 contains a generated string — safe to ignore in this local lab.
- SonarQube token is stored in `sonarqube/token.md` locally.
- Vault root token is printed during `vault operator init` — save it immediately.
