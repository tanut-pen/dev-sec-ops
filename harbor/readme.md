# Harbor

## What Is This Tool

Harbor is a container registry. It stores Docker images and can also provide image scanning, project-based access control, and artifact management.

In this project, Harbor is used as the private image registry where Jenkins can push built container images.

## How It Works

This folder contains:

- `install.sh` to install Harbor with Helm
- `harbor-local.yaml` to configure Harbor for local Kubernetes usage

In this repo, Jenkins builds an image and can push it to Harbor when the `PUSH_TO_HARBOR` parameter is enabled.

The configured image naming pattern in the pipeline is:

```text
10.72.110.5:30002/my-project/getting-started-todo-app:<build-number>
```

## When We Need It

Use Harbor when you need:

- a private container registry
- a central place to store images built by CI
- image distribution inside Kubernetes or internal environments
- better control over image ownership and lifecycle

## How To Apply To Kubernetes Cluster

### Prerequisites

- Kubernetes cluster is running
- `helm` is installed

### Add The Helm Repository

```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
```

### Install Harbor

From this folder:

```bash
helm install my-harbor harbor/harbor -f harbor-local.yaml -n harbor --create-namespace
```

Or run:

```bash
./install.sh
```

### Current Settings In This Repo

- Namespace: `harbor`
- Exposure type: `NodePort`
- HTTP only
- TLS disabled
- NodePort: `30002`
- External URL: `http://localhost:30002`

### Access Harbor

```text
http://localhost:30002
```

## Notes

- The folder name is `Habor`, but the tool is Harbor.
- TLS is disabled in this local setup. That is acceptable for a lab, but not for production.

kubectl create secret docker-registry regcred \
  --docker-server=harbor.local \
  --docker-username=YOUR_USERNAME \
  --docker-password=YOUR_PASSWORD \
  --docker-email=your@email.com \
  --namespace=your-namespace