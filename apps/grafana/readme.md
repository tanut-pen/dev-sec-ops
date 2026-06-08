# Grafana Stack

## What Is This Tool

Grafana Stack in this repo is deployed with the `kube-prometheus-stack` Helm chart. It bundles Grafana for dashboards, Prometheus for metrics collection, and Alertmanager for alert routing.

In this local lab, it gives us a monitoring layer for the Kubernetes-based DevSecOps platform components already installed in the cluster.

## How It Works

This folder contains:

- `install.sh` to install the Grafana stack with Helm
- `values-grafana.yaml` to configure Grafana, Prometheus, and Alertmanager

The Helm chart comes from the Prometheus Community repository and is installed as a single release named `grafana` in the `grafana` namespace.

## When We Need It

Use this stack when you need:

- dashboards for cluster and application metrics
- Prometheus scraping and local metrics retention
- alerting capabilities through Alertmanager
- a simple monitoring view for the local DevSecOps lab

## How To Apply To Kubernetes Cluster

### Prerequisites

- Kubernetes cluster is running
- `helm` is installed

### Add The Helm Repository

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Install The Grafana Stack

From this folder:

```bash
helm upgrade --install grafana prometheus-community/kube-prometheus-stack \
  -n grafana \
  --create-namespace \
  -f values-grafana.yaml
```

Or run:

```bash
./install.sh
```

### Current Settings In This Repo

- Namespace: `grafana`
- Helm release: `grafana`
- Chart: `prometheus-community/kube-prometheus-stack`
- Grafana service type: `NodePort`
- Grafana NodePort: `30005`
- Grafana persistence: `2Gi`
- Prometheus retention: `7d`
- Prometheus persistence: `5Gi`
- Alertmanager persistence: `2Gi`

### Access Grafana

```text
http://localhost:30005
```

Default Grafana login in this repo:

```text
admin / admin
```

## Notes

- The first login may prompt for a password change.
- This configuration is sized for a local lab and should be reviewed before production use.
