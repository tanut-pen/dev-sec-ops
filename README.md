# DevSecOps Lab

A GitOps-driven DevSecOps lab on Kubernetes. It bundles the CI/CD, security scanning, registry, secrets, gateway and observability tooling needed to run a secure delivery pipeline end to end, plus VM-based environments (RKE2, GitLab) to host it.

## Contents

- [What's included](#whats-included)
- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Deploying apps](#deploying-apps)
- [Service ports](#service-ports)
- [Ingress](#ingress)
- [Jenkins pipelines](#jenkins-pipelines)
- [VM environments](#vm-environments)
- [Secrets](#secrets)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

## What's included

| Area | Tools |
|------|-------|
| CI/CD | Jenkins, Argo CD, Argo Rollouts, GitLab (VM) |
| Code & image security | SonarQube, Trivy, OWASP ZAP, DefectDojo |
| Registry | Harbor |
| Secrets | Vault, Sealed Secrets (kubeseal) |
| Networking | Kong Gateway, Istio, Envoy AI Gateway |
| AI gateways | LiteLLM, Bifrost, Kubernetes MCP server, MCP server |
| Observability | Grafana / Prometheus, Loki, Tempo, Grafana Alloy, Uptime Kuma |
| Data & messaging | Postgres, MySQL, RabbitMQ |
| Cluster UI | Portainer, Headlamp |

## Repository layout

```text
.
├── apps/                       # One folder per service (Helm values, manifests, install.sh)
│   ├── bifrost/                # Bifrost AI gateway
│   ├── custom_microservice/    # Demo workloads (echo, httpbin) deployed via Argo CD
│   ├── defectdojo/
│   ├── envoy/                  # Envoy AI Gateway
│   ├── harbor/
│   ├── istio/
│   ├── jenkins/                # Jenkins + demo and ZAP pipelines
│   ├── jenkins-dashboard/
│   ├── kong/
│   ├── kubernetes-mcp-server/
│   ├── kubeseal/
│   ├── litellm/
│   ├── loki/
│   ├── mcpserver/
│   ├── monitoring/             # Grafana, Alloy and Tempo values
│   ├── mysql/
│   ├── portainer/
│   ├── postgres/
│   ├── rabbitmq/
│   ├── sonarqube/
│   ├── uptime-kuma/
│   ├── vault/
│   └── vulnerability-application/
├── argocd/                     # Argo CD install, values and the root ApplicationSet
├── gitlab/                     # Vagrant setups for a GitLab server (web) and runner
├── headlamp/                   # Headlamp install
├── static/                     # Cluster-wide Ingress and RBAC manifests
├── vm/                         # RKE2 multi-node lab (Vagrant) and Rancher Manager
└── apply.sh                    # Bootstrap: Argo CD, root ApplicationSet, Postgres
```

Most folders under `apps/` have their own `readme.md` with service-specific details.

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Docker](https://docs.docker.com/get-docker/) or [Rancher Desktop](https://rancherdesktop.io/) | Container runtime |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | Cluster CLI |
| [Helm](https://helm.sh/docs/intro/install/) | Installs the charts |
| A Kubernetes cluster | Rancher Desktop, k3d, or the RKE2 lab in [`vm/`](vm/README.md) |
| [kubeseal](https://github.com/bitnami-labs/sealed-secrets#installation) | Encrypting secrets (optional) |
| [Vagrant](https://developer.hashicorp.com/vagrant) + VMware Fusion | Only for the `vm/` and `gitlab/` environments |

Recommended: 8 GB RAM minimum (16 GB for the full stack) and 30 GB free disk.

Check your setup:

```bash
docker --version && kubectl version --client && helm version
kubectl get nodes
```

## Getting started

1. Clone the repo and point `kubectl` at your cluster.

   ```bash
   git clone git@github.com:tanut-pen/dev-sec-ops.git
   cd dev-sec-ops
   kubectl config current-context
   ```

2. Bootstrap GitOps. This installs Argo CD and Argo Rollouts, applies the root ApplicationSet, then installs Postgres.

   ```bash
   ./apply.sh
   ```

   `argocd/install.sh` prints the initial `admin` password at the end.

3. Install any other service by running its script:

   ```bash
   ./apps/jenkins/install.sh
   ./apps/sonarqube/install.sh
   ./apps/harbor/install.sh
   ```

Each `install.sh` adds the Helm repo and runs `helm upgrade --install` into its own namespace, using the values file in the same folder. Read a script before running it, since some set NodePorts or expect local credentials.

## Deploying apps

### Through Argo CD (GitOps)

[`argocd/app-of-apps.yaml`](argocd/app-of-apps.yaml) defines an ApplicationSet that creates one Application per listed directory. It currently deploys:

| Directory | Source |
|-----------|--------|
| `apps/custom_microservice` | Plain manifests (namespace `demo`) |
| `apps/vault` | Vault Helm chart + `apps/vault/vault-values.yaml` |
| `apps/bifrost` | Bifrost Helm chart + `apps/bifrost/bifrost-values.yaml` |

To deploy another app through Argo CD, add its path to the `directories` list in the ApplicationSet. Applications use automated sync with prune and self-heal, so Git is the source of truth.

Other app lists live in `argocd/` (`app-list-all.yaml`, `app-list-demo.yaml`, `app-list-grafana.yaml`, `app-list-mcpserver.yaml`).

### Directly with Helm

Run the app's `install.sh`. Use this for services not managed by Argo CD.

## Service ports

NodePorts set in the install scripts and values files. Check the script for the current value, since these can change.

| Service | Port |
|---------|------|
| Jenkins | 30003 |
| Argo CD | 30004 |
| Grafana | 30005 |
| Uptime Kuma | 30006 |
| Kong Admin API | 30007 |
| Kong HTTP / HTTPS proxy | 30008 / 30009 |
| Portainer HTTP / HTTPS | 30777 / 30779 |
| Istio ingress HTTP / HTTPS | 30080 / 30443 |

## Ingress

Ingress rules live in [`static/`](static/):

| File | Purpose |
|------|---------|
| `ingress.yaml` | Hosts for Jenkins, Argo CD, Harbor, DefectDojo, Kong and LiteLLM |
| `kong-ingress.yaml` | Kong-class ingresses |
| `jenkins-argocd-rbac.yaml` | RBAC letting Jenkins work with Argo CD |
| `remoteadmintoken.yaml` | Remote admin token resource |

```bash
kubectl apply -f static/ingress.yaml
```

For `*.local` hosts, add entries to `/etc/hosts` that point at your cluster ingress IP.

## Jenkins pipelines

Pipelines are under `apps/jenkins/`:

- `demo/Jenkinsfile`: secure CI flow for a sample Node.js app.
- `zap/Jenkinsfile`: OWASP ZAP scan.
- `lib/`: shared pipeline code.

The demo pipeline:

1. Clones the demo application.
2. Installs dependencies and runs tests if a `test` script exists.
3. Runs SonarQube analysis.
4. Builds a Docker image.
5. Scans the image with Trivy.
6. Optionally pushes the image to Harbor (`PUSH_TO_HARBOR`).
7. Optionally imports the Trivy report into DefectDojo (`IMPORT_TO_DEFECTDOJO`).

It runs in a Kubernetes agent pod with `nodejs`, `docker-cli`, `trivy` and `curl` containers.

Create these credentials in Jenkins (Manage Jenkins → Credentials):

| ID | Type | Used for |
|----|------|----------|
| `harbor-credentials` | Username/Password | Pushing images to Harbor |
| `defectdojo-api-token` | Secret text | Importing Trivy reports |
| `sonar` | Secret text | SonarQube analysis |

See [`apps/jenkins/README.MD`](apps/jenkins/README.MD) for more.

## VM environments

- [`vm/`](vm/README.md): a three-node RKE2 cluster on VMware Fusion with Vagrant, plus [Rancher Manager](vm/rancher-manager.md). Use it as a cluster for this lab.
- `gitlab/web` and `gitlab/runner`: Vagrant setups for a self-hosted GitLab server and a runner.

For the GitLab runner, set these environment variables before `vagrant up`:

| Variable | Purpose |
|----------|---------|
| `GITLAB_URL` | URL of your GitLab instance (empty by default) |
| `GITLAB_RUNNER_TOKEN` | Runner registration token |
| `RUNNER_DNS_SERVERS` | Comma-separated DNS servers for the VM |

## Secrets

Never commit real credentials. This repo's `.gitignore` excludes `.env*` and `secret*.yaml`.

- **Local use:** environment variables.
- **Cluster workloads:** Kubernetes Secrets. See `apps/mcpserver/secret.yaml.example` for the pattern.
- **Safe to commit:** Sealed Secrets, which are encrypted for your cluster.

  ```bash
  kubectl create secret generic my-secret --from-literal=key=value --dry-run=client -o yaml \
    | kubeseal --format yaml > sealed-secret.yaml
  ```

- **Central store:** Vault. After installing, run `vault operator init` to get the unseal keys and root token, and store them somewhere safe.

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Pod stuck in `Pending` | `kubectl describe pod <pod> -n <ns>`. Usually low resources, an unbound PVC, or image pull errors. |
| Helm install fails | `helm repo update`, then `helm list -n <ns>` to look for a conflicting release. |
| Port already in use | `lsof -i :<port>`, or change the NodePort in the install script or values file. |
| Service won't start | `kubectl logs -n <ns> <pod>` and `kubectl get events -n <ns>`. |
| Argo CD app out of sync | Check the Application in the Argo CD UI, or run `kubectl describe application <name> -n argocd`. |
| Need a shell in a pod | `kubectl exec -it <pod> -n <ns> -- sh` |

## Cleanup

Remove one service:

```bash
helm uninstall <release> -n <namespace>
kubectl delete namespace <namespace>
```

Remove Argo CD and the apps it manages:

```bash
kubectl delete -f argocd/app-of-apps.yaml
helm uninstall argo-rollouts -n argo-rollouts
helm uninstall argocd -n argocd
```

Deleting the ApplicationSet also deletes the Applications and their resources, because they carry a cleanup finalizer.
