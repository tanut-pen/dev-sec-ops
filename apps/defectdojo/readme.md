# DefectDojo

## What Is This Tool

DefectDojo is a vulnerability management platform. It collects, organizes, and tracks findings from security scanners in one place.

In this project, DefectDojo is used to import Trivy scan reports from Jenkins so vulnerabilities can be tracked centrally.

## How It Works

This folder contains:

- `install.sh` to install DefectDojo with Helm
- `values-dojo.yaml` to configure the deployment

In this repo, Jenkins uploads the generated `trivy-report.json` file to the DefectDojo API using the `import-scan` endpoint.

The pipeline uses:

- scan type: `Trivy Scan`
- product name: `getting-started-todo-app`
- engagement id: `1`

## When We Need It

Use DefectDojo when you need:

- centralized vulnerability tracking
- a place to collect findings from multiple scanners
- better visibility of security issues over time
- simple reporting for development and security teams

## How To Apply To Kubernetes Cluster

### Prerequisites

- Kubernetes cluster is running
- `helm` is installed
- DefectDojo Helm repository is already added

If needed, add the repo:

```bash
helm repo add defectdojo https://raw.githubusercontent.com/DefectDojo/django-DefectDojo/helm-charts
helm repo update
```

### Install DefectDojo

From this folder:

```bash
helm upgrade --install defectdojo defectdojo/defectdojo -n defectdojo --create-namespace \
  -f values-dojo.yaml \
  --set createSecret=true \
  --set createValkeySecret=true \
  --set createPostgresqlSecret=true \
  --set django.ingress.enabled=false
```

Or run:

```bash
./install.sh
```

### Current Settings In This Repo

- Namespace: `defectdojo`
- Service type: `NodePort`
- NodePort: `30001`
- PostgreSQL persistence enabled
- Valkey persistence enabled
- Ingress disabled

### Access DefectDojo

```text
http://localhost:30001
```

## Notes

- The values file allows localhost and a specific private IP in `DD_ALLOWED_HOSTS`.
- For production, secrets and host settings should be tightened and managed outside plain text files.
