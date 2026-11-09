# Bifrost AI Gateway

[Bifrost](https://github.com/maximhq/bifrost) is an open-source, high-performance AI, LLM, and MCP gateway by Maxim AI.
This directory installs it via the official Bifrost Helm chart (`https://maximhq.github.io/bifrost/helm-charts`) into the `bifrost` namespace.

## Files

| File | Description |
|------|-------------|
| `install.sh` | Add Bifrost Helm repo and deploy Bifrost |
| `bifrost-values.yaml` | Custom Helm values for this lab |

## Install

```bash
cd apps/bifrost
./install.sh
```

Or sync via Argo CD (`apps/bifrost` in `argocd/app-of-apps.yaml`).

## Access

- In-cluster: `http://bifrost.bifrost.svc.cluster.local:8080`
- NodePort: `http://localhost:30008`

## Uninstall

```bash
helm uninstall bifrost --namespace bifrost
```

