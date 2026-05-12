# Istio

## What Is This Tool

Istio provides a service mesh for Kubernetes workloads. In this local lab it installs the Istio base CRDs, the `istiod` control plane, and an ingress gateway exposed with NodePort services.

## How It Works

This folder contains:

- `install.sh` to install Istio with Helm
- `base-values.yaml` for Istio CRDs and cluster-scoped base resources
- `istiod-values.yaml` for the control plane
- `gateway-values.yaml` for the ingress gateway

The Helm charts come from the official Istio Helm repository.

## How To Apply To Kubernetes Cluster

### Prerequisites

- Kubernetes cluster is running
- `helm` is installed

### Add The Helm Repository

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

### Install Istio

From this folder:

```bash
./install.sh
```

Or install the charts manually:

```bash
helm upgrade --install istio-base istio/base \
  -n istio-system \
  --create-namespace \
  --wait \
  -f base-values.yaml

helm upgrade --install istiod istio/istiod \
  -n istio-system \
  --wait \
  -f istiod-values.yaml

helm upgrade --install istio-ingress istio/gateway \
  -n istio-ingress \
  --create-namespace \
  -f gateway-values.yaml
```

### Install Kiali

From this folder:

```bash
./Kiali.sh
```

Or install Kiali and the Istio Prometheus addon manually:

```bash
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.21/samples/addons/kiali.yaml
```

### Start the Kiali Dashboard

Kiali is installed into the `istio-system` namespace and exposes a ClusterIP service.

Run this port-forward command from your local machine:

```bash
kubectl -n istio-system port-forward svc/kiali 20001:20001
```

Then open the dashboard in your browser:

```text
http://localhost:20001/
```

If you need to access Kiali without port forwarding, create an ingress or NodePort service for `svc/kiali` in the `istio-system` namespace.

### Current Settings In This Repo

- Base namespace: `istio-system`
- Ingress namespace: `istio-ingress`
- Helm releases: `istio-base`, `istiod`, `istio-ingress`
- Istio profile: `default`
- Ingress gateway service type: `NodePort`
- HTTP NodePort: `30080`
- HTTPS NodePort: `30443`

## Notes

- Istio base should be installed before `istiod`.
- Label namespaces with `istio-injection=enabled` when you want automatic sidecar injection.
