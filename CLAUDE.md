# CLAUDE.md — Token & Credential Reference

> ⚠️ **Do NOT commit real credentials here in a shared/production repo.**
> This file is for local lab use only.

## Service Credentials

## MCP Servers (in-cluster)

| Server | SSE URL |
|--------|---------|
| Jenkins MCP | `http://mcp-jenkins.jenkins.svc.cluster.local:9887/sse` |
| Kubernetes MCP | `http://kubernetes-mcp-server.kubernetes-mcp-server.svc.cluster.local:8080/sse` |

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
helm repo add istio         https://istio-release.storage.googleapis.com/charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana       https://grafana.github.io/helm-charts
helm repo add hashicorp    https://helm.releases.hashicorp.com
helm repo add uptime-kuma  https://helm.irsigler.cloud
helm repo add kong         https://charts.konghq.com
helm repo update
```

## Notes

- Jenkins `install.sh` line 3 contains a generated string — safe to ignore in this local lab.
- SonarQube token is stored in `sonarqube/token.md` locally.
- Vault root token is printed during `vault operator init` — save it immediately.
