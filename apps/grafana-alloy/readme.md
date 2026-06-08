# Grafana Alloy

## What Is This Tool

Grafana Alloy is an OpenTelemetry Collector distribution with built-in Prometheus-compatible pipelines. In this repo it runs as a Kubernetes DaemonSet and sends its own scrape metrics to the local Prometheus instance from `kube-prometheus-stack`.

## How It Works

This folder contains:

- `install.sh` to install Grafana Alloy with Helm
- `values.yaml` to configure the Alloy DaemonSet and pipeline

The Helm chart comes from the Grafana Helm repository and is installed as a release named `grafana-alloy` in the `grafana-alloy` namespace.

## How To Apply To Kubernetes Cluster

### Prerequisites

- Kubernetes cluster is running
- `helm` is installed
- Grafana stack is installed in the `grafana` namespace

### Add The Helm Repository

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Install Grafana Alloy

From this folder:

```bash
helm upgrade --install grafana-alloy grafana/alloy \
  -n grafana-alloy \
  --create-namespace \
  -f values.yaml
```

Or run:

```bash
./install.sh
```

### Current Settings In This Repo

- Namespace: `grafana-alloy`
- Helm release: `grafana-alloy`
- Chart: `grafana/alloy`
- Controller: `DaemonSet`
- Anonymous usage reporting: disabled
- ServiceMonitor: enabled
- Remote write target: `http://grafana-kube-prometheus-prometheus.grafana.svc.cluster.local:9090/api/v1/write`

## Notes

- The local Prometheus instance must allow remote write receiver traffic for Alloy metrics to be accepted.
- This configuration is intentionally small and can be extended later for logs, traces, or application metrics.
