# DevSecOps Local Lab

This repository provisions a small local DevSecOps environment on Kubernetes and includes a Jenkins pipeline that demonstrates a basic secure CI flow.

## What is DevSecOps?

**DevSecOps** means integrating security practices throughout the entire software development lifecycle (development, security, and operations). This lab demonstrates a complete pipeline where:

- **Code is scanned** for vulnerabilities (SonarQube)
- **Container images are checked** for security issues (Trivy)
- **Vulnerabilities are tracked** and managed (DefectDojo)
- **Changes are deployed safely** using GitOps (Argo CD)
- **Health is monitored** (Grafana, Uptime Kuma)
- **Secrets are managed securely** (Vault, Kubeseal)

This lab gives you hands-on experience with real DevSecOps tools in a local, safe environment.

## The stack in this repo includes:

- `k3d` for a local Kubernetes cluster
- `Helm` for installing platform components
- `Jenkins` for CI/CD orchestration
- `SonarQube` for static code analysis
- `Harbor` for container image storage
- `DefectDojo` for vulnerability report import and tracking
- `Argo CD` for GitOps-style delivery
- `Istio` for service mesh traffic management
- `Grafana Stack` for monitoring, dashboards, and alerting
- `Grafana Alloy` for telemetry collection pipelines
- `Trivy` for container image scanning
- `Vault` for secrets management
- `Uptime Kuma` for uptime monitoring
- `Portainer` for Kubernetes UI management
- `Kubeseal` (Sealed Secrets) for encrypted Kubernetes secrets
- `Kong Gateway` as an API gateway and Kubernetes Ingress controller
- `GitLab` as an optional self-hosted Git server
- `Postgres` for database services
- `LiteLLM` for AI model routing and proxying

## Project Structure

```text
.
├── apps/                  # Application and service deployments
│   ├── alpine/
│   ├── custom_microservice/
│   ├── defectdojo/
│   ├── grafana/
│   ├── grafana-alloy/
│   ├── harbor/
│   ├── istio/
│   ├── jenkins/
│   ├── kong/
│   ├── kubernetes-mcp-server/
│   ├── kubeseal/
│   ├── litellm/
│   ├── mysql/
│   ├── nginx/
│   ├── ollama-deepseek/
│   ├── ollama-qwen/
│   ├── portainer/
│   ├── postgres/
│   ├── sonarqube/
│   ├── uptime-kuma/
│   ├── vault/
│   └── vulnerability-application/
├── argocd/                # Argo CD bootstrap and control plane config
│   ├── app-list.yaml      # Argo CD Application list
│   └── app-of-apps.yaml   # Root app-of-apps bootstrap Application
├── static/                # Cluster-wide static resources (Ingresses, RBAC)
├── CLAUDE.md              # Token & credential reference
└── apply.sh               # Bootstrap script
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

You need to install these tools on your machine before using this repository. **Don't worry if you don't have them yet — installation links and instructions are below.**

### Required Tools

| Tool | Purpose | Installation |
|------|---------|---------------|
| **Docker** | Container runtime; runs your applications in isolated environments | [Install Docker](https://docs.docker.com/get-docker/) |
| **Kubernetes (kubectl)** | Command-line tool to interact with Kubernetes clusters | [Install kubectl](https://kubernetes.io/docs/tasks/tools/) |
| **Helm** | Package manager for Kubernetes; installs and manages applications | [Install Helm](https://helm.sh/docs/intro/install/) |
| **k3d** | Creates lightweight local Kubernetes clusters using Docker | [Install k3d](https://k3d.io/#installation) |
| **Kubeseal CLI** | Encrypts secrets for Kubernetes | [Install kubeseal](https://github.com/bitnami-labs/sealed-secrets#installation) |

### System Requirements

- **OS**: macOS, Linux, or Windows (with WSL2)
- **RAM**: Minimum 8GB (16GB recommended for comfortable operation)
- **Disk**: At least 30GB free space
- **Container Runtime**: Docker or Rancher Desktop (both work with this project)

#### Docker or Rancher Desktop?

**Docker Desktop** — Traditional choice, industry standard. Requires Docker subscription for organizations.

**Rancher Desktop** *(Recommended for this project)* — Free, open-source alternative with built-in Kubernetes support. Works seamlessly with k3d and includes all necessary components. [Install Rancher Desktop](https://rancherdesktop.io/)

If using **Rancher Desktop**, you get:
- ✅ Integrated Kubernetes (can skip k3d if you prefer)
- ✅ Built-in containerd runtime
- ✅ Free and open-source
- ✅ No enterprise subscription required
- ✅ Full compatibility with this project

**Note:** This project requires container socket access (`/var/run/docker.sock` or Rancher Desktop equivalent). Both Docker Desktop and Rancher Desktop provide this by default.

### Quick Verification

After installing, verify everything is working:

```bash
docker --version
kubectl version --client
helm version
k3d version
kubeseal --version
```

If all commands show version numbers, you're ready to proceed!

## Quick Start (5–10 minutes)

**Want to see it working quickly? Try this minimal setup:**

```bash
# 1. Clone this repository
git clone <your-repo-url>
cd dev-sec-ops

# 2. Create a local Kubernetes cluster (takes ~2 minutes)
./k3d/start.sh

# 3. Verify the cluster is running
kubectl get nodes

# 4. Install just Jenkins and SonarQube (the essentials)
cd apps/jenkins && ./install.sh && cd ../..
cd apps/sonarqube && ./install.sh && cd ../..

# 5. Get Jenkins admin password
kubectl get secret -n jenkins $(kubectl get secret -n jenkins -o name | grep jenkins) -o jsonpath='{.data.jenkins-admin-password}' | base64 --decode

# 6. Access Jenkins at http://localhost:30003
```

That's it! You now have a working Jenkins + SonarQube pipeline running locally. To add more tools, follow the **Full Setup** section below.

---

## Full Setup Flow

### 1. Create the local cluster

```bash
cd apps/k3d  # or wherever k3d/start.sh is located
./start.sh
```

Creates a cluster named `my-cluster` with:

- 1 server node, 1 agent node
- K3s image `rancher/k3s:v1.22.7-k3s1-amd64`

**Verify:**

```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

You should see 2 nodes in "Ready" status.

### 2. Install Jenkins

```bash
cd apps/jenkins
./install.sh
```

- Namespace: `jenkins`
- Service type: `NodePort` — port `30003`
- Admin credentials: set by you for your local lab deployment
- Persistent volume size: `8Gi`

### 7. Install Argo CD (GitOps Deployment)

```bash
cd argocd
./install.sh
```

- Namespace: `argocd`
- Service type: `NodePort` — port `30004`
- Ingress host: `argocd.local`
- Server runs in insecure mode for local ingress compatibility
- Also installs Argo Rollouts in namespace `argo-rollouts`

### 8. Install Istio (Service Mesh)

```bash
cd apps/istio
./install.sh
```

- Base/control plane namespace: `istio-system`
- Ingress gateway namespace: `istio-ingress`
- Charts: `istio/base`, `istio/istiod`, `istio/gateway`
- Ingress gateway service type: `NodePort`
- HTTP NodePort: `30080`
- HTTPS NodePort: `30443`

**Verify:**

```bash
kubectl get pods -n istio-system
kubectl get pods -n istio-ingress
```

---

### 9. Install Grafana Stack (Monitoring)

```bash
cd apps/grafana
./install.sh
```

- Namespace: `grafana`
- Chart: `prometheus-community/kube-prometheus-stack`
- Grafana service type: `NodePort` — port `30005`
- Admin credentials: set by you for your local lab deployment
- Prometheus retention: `7d`
- Ingress host: `grafana.local`

### 10. Install Grafana Alloy (Telemetry Collection)

```bash
cd apps/grafana-alloy
./install.sh
```

- Namespace: `grafana-alloy`
- Chart: `grafana/alloy`
- Controller: `DaemonSet`
- Sends Alloy self metrics to the local Prometheus remote write endpoint

**Verify:**

```bash
kubectl get daemonsets -n grafana-alloy
```

---

### 11. Install Vault (Secrets Management)

```bash
cd apps/vault
./install.sh
```

- Namespace: `vault`
- Chart: `hashicorp/vault`
- Values file: `vault/vault-values.yaml`
- Run `vault operator init` after install to get the root token and unseal keys

### 12. Install Uptime Kuma (Monitoring)

```bash
cd apps/uptime-kuma
./install.sh
```

- Namespace: `monitoring`
- Chart: `uptime-kuma/uptime-kuma` from `helm.irsigler.cloud`
- Service type: `NodePort` — port `30006`
- 4Gi persistent volume
- Set credentials on first login

**Access:**

```bash
# Open http://localhost:30006 and set your admin credentials
```

---

### 13. Install Portainer (Kubernetes UI)

```bash
cd apps/portainer
./install.sh
```

- Namespace: `portainer`
- Chart: `portainer/portainer` (Community Edition)
- HTTP NodePort: `30777`
- HTTPS NodePort: `30779`
- 10Gi persistent volume

### 13. Install Kubeseal (Sealed Secrets)

```bash
cd apps/kubeseal
./install.sh
```

- Namespace: `kube-system`
- Chart: `sealed-secrets/sealed-secrets` from `bitnami-labs.github.io`
- Installs the controller; use the `kubeseal` CLI to encrypt secrets

### 14. Install Kong Gateway (API Gateway)

```bash
cd apps/kong
./install.sh
```

- Namespace: `kong`
- Chart: `kong/kong` from `charts.konghq.com`
- Mode: DB-less (no database required)
- Admin API NodePort: `30007` → `http://localhost:30007`
- HTTP Proxy NodePort: `30008` → `http://localhost:30008`
- HTTPS Proxy NodePort: `30009` → `https://localhost:30009`
- Kubernetes Ingress Controller enabled (uses `ingressClassName: kong`)

**Verify:**

```bash
kubectl get pods -n kong
```

---

### 15. Install GitLab *(optional)*

```bash
cd apps/gitlab
./install.sh
```

- Namespace: `gitlab`
- Requires a real domain and external IP before use
- Edit `install.sh` to set `global.hosts.domain`, `global.hosts.externalIP`, and `certmanager-issuer.email`

## Ingress Rules (`ingress.yaml`)

The `ingress.yaml` under the `static/` directory defines rules for:

- `jenkins.tpinf.xyz` → `jenkins:8080`
- `argocd.local` → `argocd-server:80`
- `harbor.local` → `my-harbor-portal:80`
- `defectdojo.local` → `defectdojo-django:80`
- `api.tpinf.xyz` → `kong-kong-proxy:80`
- `litellm.tpinf.xyz` → `litellm:4000`

Apply with:

```bash
kubectl apply -f static/ingress.yaml
```

## Credentials and Secrets Management

### Security Best Practices

**Never commit real credentials to Git.** Instead:

1. **Environment Variables** (for local development)
   ```bash
   export HARBOR_PASSWORD="your-password"
   ```

2. **Kubernetes Secrets** (for cluster workloads)
   ```bash
   kubectl create secret generic harbor-credentials \
     --from-literal=username=admin \
     --from-literal=password=yourpassword \
     -n jenkins
   ```

3. **Sealed Secrets** (encrypted in Git, safe to commit)
   ```bash
   echo -n 'your-secret' | kubectl create secret generic my-secret --dry-run=client --from-file=/dev/stdin -o yaml | kubeseal > sealed-secret.yaml
   ```

4. **Vault** (enterprise-grade secrets management)
   ```bash
   vault kv put secret/myapp password="yourpassword"
   ```

### Initial Setup: Jenkins Credentials

After Jenkins is installed, add these credentials in the Jenkins UI (Manage Jenkins → Credentials):

| Credential ID | Type | Value | Usage |
|---|---|---|---|
| `harbor-credentials` | Username/Password | Harbor admin user | Push images to Harbor |
| `defectdojo-api-token` | Secret text | DefectDojo API token | Import vulnerability reports |
| `sonar` | Secret text | SonarQube token | Run code analysis |

**How to get DefectDojo API Token:**

```bash
# Port-forward to DefectDojo
kubectl port-forward -n defectdojo svc/defectdojo-django 8000:8000 &
# Visit http://localhost:8000 and login
# Go to User Profile → API Key → Generate new key
```

## Jenkins Pipeline Overview

The demo pipeline definition is in `jenkins/demo/Jenkinsfile`.

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
<harbor-host>:<harbor-port>/my-project/getting-started-todo-app:<build-number>
```

### Jenkins credentials required

| Credential ID | Type | Usage |
|---------------|------|-------|
| `harbor-credentials` | Username/Password | Push images to Harbor |
| `defectdojo-api-token` | Secret text | Import Trivy reports |
| `sonar` | Secret text | SonarQube analysis |

## Troubleshooting

### Common Issues and Solutions

#### "kubectl: command not found"

**Solution:** kubectl is not installed or not in PATH. See [Prerequisites](#prerequisites) for installation instructions.

#### Cluster won't start with k3d

```bash
# Check if Docker is running
docker ps

# If error, start Docker and try again
./k3d/start.sh

# Check cluster status
k3d cluster list
```

#### Pod stuck in "Pending" state

```bash
# Check pod status and events
kubectl describe pod POD_NAME -n NAMESPACE

# Common causes:
# - Insufficient resources (CPU/memory)
# - PersistentVolume not available
# - Image pull errors
```

#### Helm install fails

```bash
# Update Helm repositories
helm repo update

# Check for conflicting releases
helm list -n NAMESPACE

# If stuck, uninstall and retry
helm uninstall RELEASE_NAME -n NAMESPACE
```

#### Port already in use (e.g., port 30003)

```bash
# Check what's using the port
lsof -i :30003

# Either:
# 1. Kill the process: kill -9 PID
# 2. Or use a different port by editing install.sh
```

#### Jenkins won't start after install

```bash
# Check logs
kubectl logs -n jenkins -l app=jenkins --tail=50

# Verify PVC is bound
kubectl get pvc -n jenkins

# Restart pod if stuck
kubectl rollout restart deployment jenkins -n jenkins
```

#### How to debug any pod

```bash
# Get logs
kubectl logs -n NAMESPACE POD_NAME

# Get detailed info
kubectl describe pod POD_NAME -n NAMESPACE

# Get shell access
kubectl exec -it POD_NAME -n NAMESPACE -- /bin/bash

# Check events
kubectl get events -n NAMESPACE
```

#### Need to restart everything?

```bash
# Delete and recreate cluster
k3d cluster delete my-cluster
./k3d/start.sh
```

---

## Cleanup and Uninstall

### Remove Individual Components

```bash
# Uninstall a specific service
helm uninstall RELEASE_NAME -n NAMESPACE

# Example: Remove Jenkins
helm uninstall jenkins -n jenkins
kubectl delete namespace jenkins
```

### Remove All Installed Services

```bash
# From repository root
helm uninstall jenkins -n jenkins 2>/dev/null
helm uninstall sonarqube -n sonarqube 2>/dev/null
helm uninstall my-harbor -n harbor 2>/dev/null
helm uninstall defectdojo -n defectdojo 2>/dev/null
helm uninstall argocd -n argocd 2>/dev/null
helm uninstall istio -n istio-system 2>/dev/null
helm uninstall kube-prometheus-stack -n grafana 2>/dev/null
helm uninstall grafana-alloy -n grafana-alloy 2>/dev/null
helm uninstall vault -n vault 2>/dev/null
helm uninstall uptime-kuma -n monitoring 2>/dev/null
helm uninstall portainer -n portainer 2>/dev/null
helm uninstall sealed-secrets -n kube-system 2>/dev/null
helm uninstall kong -n kong 2>/dev/null

# Clean up namespaces
kubectl delete namespace jenkins sonarqube harbor defectdojo argocd istio-system grafana grafana-alloy vault monitoring portainer kong
```

### Completely Delete the Cluster

```bash
# WARNING: This deletes everything, including persistent data!
k3d cluster delete my-cluster
```

### Verification After Cleanup

```bash
# Verify cluster is clean
kubectl get namespaces
kubectl get all --all-namespaces
```

---

## Compatibility Notes

### Rancher Desktop Support

✅ **This project is fully compatible with Rancher Desktop.**

Rancher Desktop users can:
1. Skip Docker Desktop installation entirely
2. Use Rancher Desktop's built-in container runtime
3. Still use k3d to create Kubernetes clusters (recommended for consistency)
4. Or use Rancher Desktop's built-in Kubernetes directly

**Setup with Rancher Desktop:**

```bash
# Option 1: Use k3d with Rancher Desktop (recommended)
# Rancher Desktop provides the container runtime for k3d
./k3d/start.sh

# Option 2: Use Rancher Desktop's built-in Kubernetes directly
# Enable Kubernetes in Rancher Desktop settings, then:
kubectl config use-context rancher-desktop
```

---

## Notes and Limitations

- This repository is intentionally scoped as a local lab and portfolio demo, not a production-hardened platform.
- Any sensitive values used during local testing should be injected at deploy/runtime (Kubernetes Secrets, Vault, or CI secret stores), not committed to source control.
- The SonarQube install script uses inline `--set` flags instead of `values-sonar.yaml`.
- The Jenkins pipeline mounts the host Docker socket — convenient for a lab, not for hardened production.
- Jenkins artifacts currently use mixed paths/file names (`values.yaml` vs `jenkins-values.yaml`, `jenkins/Jenkinsfile` vs `jenkins/demo/Jenkinsfile`). Align these before running seed jobs.
- GitLab requires significant resources and external DNS; it is included as a reference install script only.
- Vault installs to namespace `vault` and still requires `vault operator init` after deploy; save unseal keys securely.

## Recommended Startup Order

```bash
./k3d/start.sh

# Install applications and controllers from the repository root
./apps/kubeseal/install.sh
./apps/harbor/install.sh
./apps/sonarqube/install.sh
./apps/defectdojo/install.sh
./apps/jenkins/install.sh
./argocd/install.sh
./apps/grafana/install.sh
./apps/vault/install.sh
./apps/uptime-kuma/install.sh
./apps/postgres/install.sh
./apps/litellm/install.sh
./apps/portainer/install.sh
./apps/kong/install.sh

# Apply shared ingress configuration
kubectl apply -f static/ingress.yaml
```

## Summary

This repository is a local DevSecOps playground for testing a secure CI workflow on Kubernetes. It combines Jenkins, SonarQube, Trivy, Harbor, DefectDojo, Argo CD, Grafana, Vault, Uptime Kuma, Portainer, Kubeseal, and Kong Gateway into a single environment suitable for demos, learning, and experimentation.

## Get Token After Applying Secret

For remote access to your Kubernetes cluster (e.g., from Portainer or external tools):

```bash
kubectl create serviceaccount remote-admin -n kube-system

kubectl create clusterrolebinding remote-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:remote-admin

kubectl get secret remote-admin-token -n kube-system -o jsonpath='{.data.token}' | base64 --decode
echo ""  # Add newline for readability
```

This creates a service account with cluster-admin permissions and outputs the access token. **Save this token securely** — it grants full cluster access.