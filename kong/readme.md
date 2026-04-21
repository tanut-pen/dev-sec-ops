# Kong Gateway

Kong is an open-source API gateway and platform built on top of Nginx/OpenResty.

## Mode

This install uses **DB-less mode** (no PostgreSQL required). Routes and services are configured via the Kubernetes Ingress Controller (KIC) using standard `Ingress` resources or Kong-specific CRDs.

## Ports

| Port  | NodePort | Description             |
|-------|----------|-------------------------|
| 8000  | 30008    | HTTP proxy (data plane) |
| 8443  | 30009    | HTTPS proxy (data plane)|
| 8001  | 30007    | Admin API (HTTP)        |

## Install

```bash
cd kong
./install.sh
```

## Verify

```bash
# Check pods
kubectl get pods -n kong

# Check services
kubectl get svc -n kong

# Ping Admin API
curl http://localhost:30007
```

## Useful Admin API examples

```bash
# List services
curl http://localhost:30007/services

# List routes
curl http://localhost:30007/routes

# List plugins
curl http://localhost:30007/plugins

# Check cluster info
curl http://localhost:30007/
```

## Switch to database-backed mode

Edit `kong-values.yaml` and change:

```yaml
env:
  database: "postgres"
```

Then configure the `postgresql` subchart or point to an external PostgreSQL instance.

## Regenerate values

```bash
helm show values kong/kong > kong-values.yaml
```

---

## Path-based Routing (kong-config.yaml)

All services are exposed through Kong proxy on a single port using path prefixes.
Access via: `http://localhost:30008/<service>/`

| Path prefix    | Upstream service                                         | Port |
|----------------|----------------------------------------------------------|------|
| `/jenkins`     | `jenkins.jenkins.svc.cluster.local`                      | 8080 |
| `/sonarqube`   | `sonarqube-sonarqube.sonarqube.svc.cluster.local`        | 9000 |
| `/harbor`      | `my-harbor-portal.harbor.svc.cluster.local`              | 80   |
| `/defectdojo`  | `defectdojo-django.defectdojo.svc.cluster.local`         | 80   |
| `/argocd`      | `argocd-server.argocd.svc.cluster.local`                 | 80   |
| `/grafana`     | `grafana-grafana.grafana.svc.cluster.local`              | 80   |
| `/uptime-kuma` | `uptime-kuma.monitoring.svc.cluster.local`               | 3001 |
| `/portainer`   | `portainer.portainer.svc.cluster.local`                  | 9000 |
| `/vault`       | `vault.default.svc.cluster.local`                        | 8200 |

> `strip_path: true` is set on all routes — Kong removes the prefix before forwarding to the upstream.

### ⚠️ Known caveats

- **Harbor** and **Argo CD** have hardcoded absolute asset paths (`/`-rooted). They may need sub-path configuration or to be accessed via their direct NodePort instead.
- **Uptime Kuma** requires WebSocket (`Upgrade: websocket`) — Kong supports this natively over HTTP.
- **Grafana** requires `GF_SERVER_ROOT_URL` set to include the subpath (`/grafana/`) in its Helm values to render assets correctly.
- **SonarQube** requires `sonar.web.context=/sonarqube` in its Helm values for sub-path support.

---

## deck Commands

```bash
# Apply config to Kong (sync)
deck gateway sync kong-config.yaml --kong-addr http://localhost:31313

# Preview changes without applying
deck gateway diff kong-config.yaml --kong-addr http://localhost:31313

# Dump current live config to file
deck gateway dump -o kong-config-new.yaml --kong-addr http://localhost:31313
```

## Dbless mode sync

```bash
curl -X POST http://localhost:31313/config \
  -F config=@kong-config.yaml
```
