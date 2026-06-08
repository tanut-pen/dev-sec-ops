# Uptime Kuma

[Uptime Kuma](https://github.com/louislam/uptime-kuma) is a self-hosted monitoring tool.
This directory installs it via the [`dirsigler/uptime-kuma-helm`](https://github.com/dirsigler/uptime-kuma-helm) chart into the `monitoring` namespace.

## Files

| File | Description |
|------|-------------|
| `install.sh` | Add Helm repo and deploy Uptime Kuma |
| `values.yaml` | Custom Helm values for this lab |

## Install

```bash
cd uptime-kuma
./install.sh
```

Or sync via Argo CD (`uptime-kuma` Application in `argocd/app-list.yaml`).

## Access

- NodePort: `http://localhost:30006`
- Ingress: `http://uptime-kuma.tpinf.xyz` (Istio ingress in `static/ingress.yaml`)

Set credentials on first login.

## Uninstall

```bash
helm delete uptime-kuma --namespace monitoring
```
