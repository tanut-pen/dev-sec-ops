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
- `Trivy` for container image scanning

## Project Structure

```text
.
├── k3d/start.sh
├── helm_install.sh
├── ingress.yaml
├── Jenkins/
│   ├── install.sh
│   ├── values-jenkins.yaml
│   └── Jenkinsfile
├── SonarCube/
│   ├── install.sh
│   ├── values-sonar.yaml
│   └── token.md
├── Habor/
│   ├── install.sh
│   └── harbor-local.yaml
└── DefectDojo/
    ├── install.sh
    └── values-dojo.yaml
```

## What This Project Does

This project is designed as a local DevSecOps lab. It creates a Kubernetes environment and installs the core tools needed to run a simple secure delivery pipeline.

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

This repo assumes you are working in a local environment where Docker is available and Kubernetes workloads can mount `/var/run/docker.sock`.

## Setup Flow

### 1. Create the local cluster

Run:

```bash
./k3d/start.sh
```

This creates a cluster named `my-cluster` with:

- 1 server node
- 1 agent node
- K3s image `rancher/k3s:v1.22.7-k3s1-amd64`

### 2. Add Helm repositories

Run:

```bash
./helm_install.sh
```

This adds the Helm repositories for:

- DefectDojo
- SonarQube
- Harbor
- Jenkins
- Argo CD

### 3. Install Jenkins

Run:

```bash
cd Jenkins
./install.sh
```

Important defaults from `Jenkins/values-jenkins.yaml`:

- Namespace: `jenkins`
- Service type: `NodePort`
- NodePort: `30003`
- Admin password: `admin`
- Persistent volume size: `5Gi`

### 4. Install SonarQube

Run:

```bash
cd SonarCube
./install.sh
```

Current install behavior from `SonarCube/install.sh`:

- Namespace: `sonarqube`
- Community mode enabled
- Monitoring passcode set during install

There is also a values file at `SonarCube/values-sonar.yaml`, but the current install script does not use it.

### 5. Install Harbor

Run:

```bash
cd Habor
./install.sh
```

Current Harbor settings from `Habor/harbor-local.yaml`:

- Exposed with `NodePort`
- HTTP only, TLS disabled
- External URL: `http://localhost:30002`
- Registry port: `30002`

### 6. Install DefectDojo

Run:

```bash
cd DefectDojo
./install.sh
```

Current DefectDojo settings from `DefectDojo/values-dojo.yaml`:

- Namespace: `defectdojo`
- Django service exposed as `NodePort`
- NodePort: `30001`
- PostgreSQL persistence enabled
- Valkey persistence enabled

### 7. Install Argo CD

Run:

```bash
cd argocd
./install.sh
```

Current Argo CD settings from `argocd/values-argocd.yaml`:

- Namespace: `argocd`
- Service type: `NodePort`
- HTTP NodePort: `30004`
- Chart ingress disabled
- Server runs in insecure mode for local ingress compatibility
- The same install script also installs Argo Rollouts in namespace `argo-rollouts`

## Accessing Services

Based on the current configuration, the main local access points are:

- Jenkins: `http://localhost:30003`
- Harbor: `http://localhost:30002`
- DefectDojo: `http://localhost:30001`
- Argo CD: `http://localhost:30004`

There is also an ingress manifest at `ingress.yaml` that defines:

- `jenkins.local`
- `sonarqube.local`
- `argocd.local`

Note: this will only work if your cluster has an Ingress controller installed and your local DNS or `/etc/hosts` is configured accordingly. The current `k3d/start.sh` script does not install an Ingress controller.

## Jenkins Pipeline Overview

The pipeline definition is in `Jenkins/Jenkinsfile`.

### Pipeline runtime

Jenkins uses a Kubernetes agent pod with multiple containers:

- `nodejs` for dependency installation and tests
- `docker-cli` for image build and push
- `trivy` for vulnerability scanning
- `curl` for DefectDojo API import

### Pipeline parameters

The pipeline exposes two boolean parameters:

- `PUSH_TO_HARBOR`
- `IMPORT_TO_DEFECTDOJO`

### Demo application source

The pipeline clones this repository:

- `https://github.com/docker/getting-started-todo-app.git`

### Image naming

The built image follows this pattern:

```text
10.72.110.5:30002/my-project/getting-started-todo-app:<build-number>
```

### External dependencies expected by Jenkins

The pipeline expects these Jenkins credentials to already exist:

- `harbor-credentials`
- `defectdojo-api-token`
- `sonar`

It also assumes SonarQube and DefectDojo are reachable from inside the cluster.

## Notes and Limitations

- The repository currently stores sensitive values in plain text, such as passwords or tokens in config files. For real use, move these into Kubernetes secrets or Jenkins credentials.
- `SonarCube/token.md` contains a token file and should not be committed in a production repository.
- `Jenkins/install.sh` contains an extra line after the Helm command that looks like a copied secret or token and should be cleaned up.
- The SonarQube install script currently installs with inline `--set` values instead of using `SonarCube/values-sonar.yaml`.
- The Harbor folder is named `Habor/`, which is likely a typo, but the current README keeps the existing folder name to match the repository.
- The Jenkins pipeline mounts the host Docker socket. That is convenient for a lab, but not a hardened production setup.

## Recommended Usage Order

If you want to bring the whole environment up from scratch, use this order:

```bash
./k3d/start.sh
./helm_install.sh

cd Habor && ./install.sh
cd ../SonarCube && ./install.sh
cd ../DefectDojo && ./install.sh
cd ../Jenkins && ./install.sh
```

Then:

1. Open Jenkins and complete the initial configuration.
2. Create the required Jenkins credentials.
3. Create a pipeline job using `Jenkins/Jenkinsfile`.
4. Run the pipeline with optional push and DefectDojo import enabled as needed.

## Summary

This repository is a local DevSecOps playground for testing a secure CI workflow on Kubernetes. It combines Jenkins, SonarQube, Trivy, Harbor, and DefectDojo into a simple environment suitable for demos, learning, and experimentation.
