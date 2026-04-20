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

## Access

- NodePort: `http://localhost:30006`
- Ingress (optional): `http://uptime-kuma.local` (requires Ingress controller + `/etc/hosts`)

## Uninstall

```bash
helm delete uptime-kuma --namespace monitoring
```
