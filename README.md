# DevSecOps Local Lab

This repository provisions a small local DevSecOps environment on Kubernetes and includes a Jenkins pipeline that demonstrates a basic secure CI flow.

The stack in this repo includes:

- `k3d` for a local Kubernetes cluster
- `Helm` for installing platform components
- `Jenkins` for CI/CD orchestration
- `SonarQube` for static code analysis
- `Harbor` for container image storage
- `DefectDojo` for vulnerability report import and tracking
- `Argo CD` for GitOps-style delivery
- `Grafana Stack` for monitoring, dashboards, and alerting
- `Trivy` for container image scanning
- `Vault` for secrets management
- `Uptime Kuma` for uptime monitoring
- `Portainer` for Kubernetes UI management
- `Kubeseal` (Sealed Secrets) for encrypted Kubernetes secrets
- `GitLab` as an optional self-hosted Git server

## Project Structure

```text
.
├── k3d/
│   ├── start.sh
│   └── readme.md
├── ingress.yaml
├── CLAUDE.md
├── jenkins/
│   ├── install.sh
│   ├── values.yaml
│   ├── readme.md
│   └── Jenkinsfile
├── sonarqube/
│   ├── install.sh
│   ├── values-sonar.yaml
│   └── readme.md
├── harbor/
│   ├── install.sh
│   ├── harbor-local.yaml
│   └── readme.md
├── defectdojo/
│   ├── install.sh
│   ├── values-dojo.yaml
│   └── readme.md
├── argocd/
│   ├── install.sh
│   ├── values-argocd.yaml
│   ├── values-rollouts.yaml
│   └── readme.md
├── grafana/
│   ├── install.sh
│   ├── values-grafana.yaml
│   └── readme.md
├── vault/
│   ├── install.sh
│   └── values.yaml
├── uptime-kuma/
│   ├── install.sh
│   ├── values.yaml
│   └── readme.md
├── portainer/
│   ├── install.sh
│   └── values.yaml
├── kubeseal/
│   └── install.sh
├── gitlab/
│   └── install.sh
└── lab/
    └── ACME/
```

## What This Project Does

This project is designed as a local DevSecOps lab. It creates a Kubernetes environment and installs the core tools needed to run a simple secure delivery pipeline.

It also includes a monitoring stack so you can observe the health of the local platform with Grafana dashboards backed by Prometheus, and Uptime Kuma for service uptime tracking.

The included Jenkins pipeline performs these steps:

1. Clone a demo application from GitHub.
2. Install Node.js dependencies for `client` and `backend`.
3. Run tests if a `test` script exists.
4. Run SonarQube analysis.
5. Build a Docker image.
6. Scan the image with Trivy.
7. Optionally push the image to Harbor.
8. Optionally import the Trivy report into DefectDojo.

## Prerequisites

Install these tools on your machine before using this repository:

- `docker`
- `kubectl`
- `helm`
- `k3d`
- `kubeseal` CLI (for Sealed Secrets)

This repo assumes you are working in a local environment where Docker is available and Kubernetes workloads can mount `/var/run/docker.sock`.

## Setup Flow

### 1. Create the local cluster

```bash
./k3d/start.sh
```

Creates a cluster named `my-cluster` with:

- 1 server node, 1 agent node
- K3s image `rancher/k3s:v1.22.7-k3s1-amd64`

### 2. Install Jenkins

```bash
cd jenkins
./install.sh
```

- Namespace: `jenkins`
- Service type: `NodePort` — port `30003`
- Admin password: `admin`
- Persistent volume size: `8Gi`

### 3. Install SonarQube

```bash
cd sonarqube
./install.sh
```

- Namespace: `sonarqube`
- Community edition
- Monitoring passcode: `admin123`
- Ingress host: `sonarqube.local`

### 4. Install Harbor

```bash
cd harbor
./install.sh
```

- Namespace: `harbor`
- HTTP only, TLS disabled
- External URL: `http://localhost:30002`
- Ingress host: `harbor.local`

### 5. Install DefectDojo

```bash
cd defectdojo
./install.sh
```

- Namespace: `defectdojo`
- Django service exposed via ingress at `defectdojo.local`
- PostgreSQL and Valkey persistence enabled

### 6. Install Argo CD

```bash
cd argocd
./install.sh
```

- Namespace: `argocd`
- Service type: `NodePort` — port `30004`
- Ingress host: `argocd.local`
- Server runs in insecure mode for local ingress compatibility
- Also installs Argo Rollouts in namespace `argo-rollouts`

### 7. Install Grafana Stack

```bash
cd grafana
./install.sh
```

- Namespace: `grafana`
- Chart: `prometheus-community/kube-prometheus-stack`
- Grafana service type: `NodePort` — port `30005`
- Admin password: `admin`
- Prometheus retention: `7d`
- Ingress host: `grafana.local`

### 8. Install Vault

```bash
cd vault
./install.sh
```

- Namespace: `default` (installs to active context namespace)
- Chart: `hashicorp/vault`
- Run `vault operator init` after install to get the root token and unseal keys

### 9. Install Uptime Kuma

```bash
cd uptime-kuma
./install.sh
```

- Namespace: `monitoring`
- Chart: `uptime-kuma/uptime-kuma` from `helm.irsigler.cloud`
- Service type: `NodePort` — port `30006`
- 4Gi persistent volume
- Set credentials on first login

### 10. Install Portainer

```bash
cd portainer
./install.sh
```

- Namespace: `portainer`
- Chart: `portainer/portainer` (Community Edition)
- HTTP NodePort: `30777`
- HTTPS NodePort: `30779`
- 10Gi persistent volume

### 11. Install Kubeseal (Sealed Secrets)

```bash
cd kubeseal
./install.sh
```

- Namespace: `kube-system`
- Chart: `sealed-secrets/sealed-secrets` from `bitnami-labs.github.io`
- Installs the controller; use the `kubeseal` CLI to encrypt secrets

### 12. Install GitLab *(optional)*

```bash
cd gitlab
./install.sh
```

- Namespace: `gitlab`
- Requires a real domain and external IP before use
- Edit `install.sh` to set `global.hosts.domain`, `global.hosts.externalIP`, and `certmanager-issuer.email`

## Accessing Services

| Service | NodePort URL | Ingress Host |
|---------|-------------|--------------|
| Jenkins | `http://localhost:30003` | `jenkins.local` |
| SonarQube | — | `sonarqube.local` |
| Harbor | `http://localhost:30002` | `harbor.local` |
| DefectDojo | — | `defectdojo.local` |
| Argo CD | `http://localhost:30004` | `argocd.local` |
| Grafana | `http://localhost:30005` | `grafana.local` |
| Uptime Kuma | `http://localhost:30006` | `uptime-kuma.local` |
| Portainer (HTTP) | `http://localhost:30777` | — |
| Portainer (HTTPS) | `https://localhost:30779` | — |

> Ingress hosts require a running Ingress controller and `/etc/hosts` entries pointing to your cluster IP.

## Ingress Rules (`ingress.yaml`)

The `ingress.yaml` at the repo root defines rules for:

- `jenkins.local` → `jenkins:8080`
- `sonarqube.local` → `sonarqube-sonarqube:9000`
- `argocd.local` → `argocd-server:80`
- `harbor.local` → `my-harbor-portal:80`
- `defectdojo.local` → `defectdojo-django:80`
- `grafana.local` → `grafana-grafana:80`

Apply with:

```bash
kubectl apply -f ingress.yaml
```

## Credentials Reference

See [`CLAUDE.md`](./CLAUDE.md) for a full table of default usernames, passwords, and tokens for each service.

## Jenkins Pipeline Overview

The pipeline definition is in `jenkins/Jenkinsfile`.

### Pipeline runtime

Jenkins uses a Kubernetes agent pod with multiple containers:

- `nodejs` for dependency installation and tests
- `docker-cli` for image build and push
- `trivy` for vulnerability scanning
- `curl` for DefectDojo API import

### Pipeline parameters

- `PUSH_TO_HARBOR`
- `IMPORT_TO_DEFECTDOJO`

### Demo application source

```
https://github.com/docker/getting-started-todo-app.git
```

### Image naming

```
10.72.110.5:30002/my-project/getting-started-todo-app:<build-number>
```

### Jenkins credentials required

| Credential ID | Type | Usage |
|---------------|------|-------|
| `harbor-credentials` | Username/Password | Push images to Harbor |
| `defectdojo-api-token` | Secret text | Import Trivy reports |
| `sonar` | Secret text | SonarQube analysis |

## Notes and Limitations

- Sensitive values (passwords, tokens) are stored in plain text in several config files. For production use, move these into Kubernetes Secrets or a secrets manager like Vault.
- The SonarQube install script uses inline `--set` flags instead of `values-sonar.yaml`.
- The Jenkins pipeline mounts the host Docker socket — convenient for a lab, not for hardened production.
- GitLab requires significant resources and external DNS; it is included as a reference install script only.
- Vault is installed without a namespace flag — run `vault operator init` after deploy and save the unseal keys securely.

## Recommended Startup Order

```bash
./k3d/start.sh

cd kubeseal && ./install.sh
cd ../harbor && ./install.sh
cd ../sonarqube && ./install.sh
cd ../defectdojo && ./install.sh
cd ../jenkins && ./install.sh
cd ../argocd && ./install.sh
cd ../grafana && ./install.sh
cd ../vault && ./install.sh
cd ../uptime-kuma && ./install.sh
cd ../portainer && ./install.sh

kubectl apply -f ingress.yaml
```

## Summary

This repository is a local DevSecOps playground for testing a secure CI workflow on Kubernetes. It combines Jenkins, SonarQube, Trivy, Harbor, DefectDojo, Argo CD, Grafana, Vault, Uptime Kuma, Portainer, and Kubeseal into a single environment suitable for demos, learning, and experimentation.
