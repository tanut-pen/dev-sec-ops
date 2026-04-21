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

## Demo — Kong as an API Gateway

The `demo/` folder contains a complete working example showing Kong's real purpose:
routing, rate-limiting, key authentication, and header injection for microservices.

### Files

| File | Purpose |
|------|---------|
| `demo/namespace.yaml` | Creates the `demo` namespace |
| `demo/echo-app.yaml` | Echo server — reflects requests as JSON |
| `demo/httpbin-app.yaml` | HTTPBin — standard HTTP testing service |
| `demo/kong-demo-config.yaml` | Kong deck config with plugins |

### Apply (in order)

```bash
# 1. Deploy the sample apps
kubectl apply -f kong/demo/namespace.yaml
kubectl apply -f kong/demo/echo-app.yaml
kubectl apply -f kong/demo/httpbin-app.yaml

# 2. Wait for pods to be ready
kubectl get pods -n demo -w

# 3. Push config to Kong (DB-less sync)
curl -X POST http://localhost:31313/config \
  -F config=@kong/demo/kong-demo-config.yaml
```

### Routes configured

| Route | URL | Auth | Plugin |
|-------|-----|------|--------|
| `/echo` | `http://localhost:30008/echo/` | None | Header injection |
| `/httpbin` | `http://localhost:30008/httpbin/get` | None | Rate-limit 10 req/min |
| `/secure` | `http://localhost:30008/secure/get` | API Key | Rate-limit 30 req/min |

### Test the routes

```bash
# 1. Echo — see all request headers and env reflected back as JSON
curl http://localhost:30008/echo/

# 2. HTTPBin — standard /get response (rate-limited to 10/min)
curl http://localhost:30008/httpbin/get

# Check rate-limit headers in response:
curl -i http://localhost:30008/httpbin/get | grep X-RateLimit

# 3. Secure endpoint — without key (returns 401)
curl http://localhost:30008/secure/get

# Secure endpoint — with API key
curl http://localhost:30008/secure/get -H "apikey: my-secret-api-key"
```

### What each plugin does

| Plugin | Service | Effect |
|--------|---------|--------|
| `request-transformer` | echo, httpbin | Adds `X-Forwarded-By: kong-gateway` header upstream |
| `rate-limiting` | httpbin | Max 10 req/min per IP; returns `429` when exceeded |
| `key-auth` | secure | Requires `apikey:` header; returns `401` without it |
| `rate-limiting` | secure | Max 30 req/min per consumer (authenticated) |

---

## deck Commands

```bash
# Apply demo config to Kong
curl -X POST http://localhost:31313/config \
  -F config=@kong/demo/kong-demo-config.yaml

# Preview changes (diff)
deck gateway diff kong-config.yaml --kong-addr http://localhost:31313

# Dump current live config to file
deck gateway dump -o kong-config-new.yaml --kong-addr http://localhost:31313

# Wipe all config (reset)
curl -X POST http://localhost:31313/config \
  -F config=@kong-config.yaml
```
