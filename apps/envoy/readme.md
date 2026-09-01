# Envoy AI Gateway

[Envoy AI Gateway](https://aigateway.envoyproxy.io/) is an open-source, Kubernetes-native AI proxy built on top of [Envoy Gateway](https://gateway.envoyproxy.io/). It provides unified API routing, model-based traffic management, multi-provider protocol translations, API key security, and rate-limiting for Large Language Model (LLM) workloads.

---

## Architecture & Request Flow

Envoy AI Gateway sits between your clients and multiple AI backends (e.g., local LM Studio, Ollama, OpenAI, Anthropic, AWS Bedrock). It dynamically parses incoming OpenAI-compatible JSON payloads, extracts metadata such as the model name, and routes requests to the appropriate upstream provider.

```
                         ┌─────────────────────┐
                         │     Client App       │
                         │ (curl, LangChain,    │
                         │  OpenWebUI, etc.)    │
                         └─────────┬───────────┘
                                   │
                          POST /v1/chat/completions
                          { "model": "...", ... }
                                   │
              ┌────────────────────▼──────────────────────┐
              │           Kubernetes Cluster               │
              │                                            │
              │  ┌──────────────────────────────────────┐  │
              │  │  Envoy Gateway Listener (Port 80)    │  │
              │  └──────────────────┬───────────────────┘  │
              │                     │                      │
              │  ┌──────────────────▼───────────────────┐  │
              │  │  AI Gateway Filter                   │  │
              │  │  1. Parse JSON body                  │  │
              │  │  2. Extract "model" field            │  │
              │  │  3. Inject header: x-ai-eg-model     │  │
              │  └──────────────────┬───────────────────┘  │
              │                     │                      │
              │  ┌──────────────────▼───────────────────┐  │
              │  │  AIGatewayRoute                      │  │
              │  │  Match on x-ai-eg-model header       │  │
              │  └───┬──────────────┬───────────────┬───┘  │
              │      │              │               │      │
              └──────┼──────────────┼───────────────┼──────┘
                     │              │               │
        ┌────────────▼──┐  ┌───────▼────────┐  ┌───▼──────────────┐
        │ LM Studio     │  │ Mock Upstream  │  │ OpenAI API       │
        │ localhost:1234 │  │ testupstream   │  │ api.openai.com   │
        │               │  │ pod :8080      │  │                  │
        │ model:        │  │                │  │ model:           │
        │ qwen3.8-27b   │  │ model: some-   │  │ gpt-4o-mini     │
        │               │  │ cool-self-     │  │                  │
        │ (Host Machine)│  │ hosted-model   │  │ (Cloud)          │
        └───────────────┘  └────────────────┘  └──────────────────┘
```

---

## Directory Structure

```text
apps/envoy/
├── install.sh
├── test_request.sh
├── readme.md
├── basic/
│   ├── GatewayClass.yaml
│   ├── Gateway.yaml
│   ├── ClientTrafficPolicy.yaml
│   ├── AIGatewayRoute.yaml
│   ├── AIServiceBackend.yaml
│   ├── Backend.yaml
│   ├── Deployment.yaml
│   ├── Service.yaml
│   └── EnvoyProxy.yaml
└── openai/
    ├── AIGatewayRoute.yaml
    ├── AIServiceBackend.yaml
    └── Backend.yaml
```

| Path | Purpose |
|------|---------|
| [`install.sh`](file:///Users/Tanut.P/SCM/github/dev-sec-ops/apps/envoy/install.sh) | Deploys Envoy Gateway, AI Gateway CRDs, and AI Gateway Controller |
| [`basic/`](file:///Users/Tanut.P/SCM/github/dev-sec-ops/apps/envoy/basic) | GatewayClass, Gateway, ClientTrafficPolicy (50MiB buffer), EnvoyProxy, and mock upstream |
| [`openai/`](file:///Users/Tanut.P/SCM/github/dev-sec-ops/apps/envoy/openai) | AIGatewayRoute, AIServiceBackend, and Backend for LM Studio (`qwen/qwen3.8-27b`) |
| [`test_request.sh`](file:///Users/Tanut.P/SCM/github/dev-sec-ops/apps/envoy/test_request.sh) | Test script to send sample chat completions to the gateway |

---

## Installation & Setup

### 1. Install Envoy AI Gateway Components

Run the installation script to install Envoy Gateway and AI Gateway controllers:

```bash
cd apps/envoy
chmod +x install.sh
./install.sh
```

### 2. Apply Base Gateway Infrastructure

Deploy the Gateway, GatewayClass, ClientTrafficPolicy, EnvoyProxy, and mock backend:

```bash
kubectl apply -f apps/envoy/basic/
```

### 3. Deploy LM Studio / OpenAI Routing

Deploy the AI route and backend configuration pointing to your local LM Studio instance:

```bash
kubectl apply -f apps/envoy/openai/
```

---

## How Model-Based Routing Works

1. **Client Request**:
   The client issues a standard OpenAI-compatible request specifying the target model in the request body:
   ```json
   {
     "model": "qwen/qwen3.8-27b",
     "messages": [
       {"role": "user", "content": "Hello!"}
     ]
   }
   ```

2. **AI Gateway Filter Inspection**:
   Envoy's AI Gateway filter inspects the JSON body and automatically injects an internal routing header:
   ```http
   x-ai-eg-model: qwen/qwen3.8-27b
   ```

3. **Route Resolution**:
   `AIGatewayRoute` matches the extracted header and dispatches the request to the corresponding `AIServiceBackend`:
   ```yaml
   apiVersion: aigateway.envoyproxy.io/v1beta1
   kind: AIGatewayRoute
   metadata:
     name: envoy-ai-gateway-basic-openai
     namespace: default
   spec:
     parentRefs:
       - name: envoy-ai-gateway-basic
         kind: Gateway
         group: gateway.networking.k8s.io
     rules:
       - matches:
           - headers:
               - type: Exact
                 name: x-ai-eg-model
                 value: qwen/qwen3.8-27b
         backendRefs:
           - name: envoy-ai-gateway-basic-openai
   ```

4. **Backend Proxying**:
   The `AIServiceBackend` forwards the call to the `Backend` resource:
   ```yaml
   apiVersion: gateway.envoyproxy.io/v1alpha1
   kind: Backend
   metadata:
     name: envoy-ai-gateway-basic-openai
     namespace: default
   spec:
     endpoints:
       - fqdn:
           hostname: host.docker.internal
           port: 1234
   ```

---

## Testing the Gateway

### 1. Export Gateway Address

```bash
export GATEWAY_URL=$(kubectl get gateway/envoy-ai-gateway-basic -o jsonpath='{.status.addresses[0].value}')
echo "Gateway URL: $GATEWAY_URL"
```

### 2. Route to LM Studio (`qwen/qwen3.8-27b`)

```bash
curl -H "Content-Type: application/json" \
  -d '{
        "model": "qwen/qwen3.8-27b",
        "messages": [
            {
                "role": "user",
                "content": "Explain Kubernetes in one sentence."
            }
        ]
    }' \
  http://$GATEWAY_URL/v1/chat/completions
```

### 3. Route to Mock Upstream (`some-cool-self-hosted-model`)

```bash
curl -H "Content-Type: application/json" \
  -d '{
        "model": "some-cool-self-hosted-model",
        "messages": [
            {
                "role": "user",
                "content": "Hello!"
            }
        ]
    }' \
  http://$GATEWAY_URL/v1/chat/completions
```

---

## Connecting External Cloud Providers (e.g. OpenAI)

To add authentications and TLS for cloud providers (like OpenAI), add `BackendSecurityPolicy` and `BackendTLSPolicy` to your manifest:

```yaml
apiVersion: aigateway.envoyproxy.io/v1beta1
kind: BackendSecurityPolicy
metadata:
  name: envoy-ai-gateway-openai-auth
  namespace: default
spec:
  targetRefs:
    - group: aigateway.envoyproxy.io
      kind: AIServiceBackend
      name: envoy-ai-gateway-openai
  type: APIKey
  apiKey:
    secretRef:
      name: openai-apikey
      namespace: default
---
apiVersion: gateway.networking.k8s.io/v1alpha3
kind: BackendTLSPolicy
metadata:
  name: envoy-ai-gateway-openai-tls
  namespace: default
spec:
  targetRefs:
    - group: "gateway.envoyproxy.io"
      kind: Backend
      name: envoy-ai-gateway-openai
  validation:
    wellKnownCACertificates: "System"
    hostname: api.openai.com
---
apiVersion: v1
kind: Secret
metadata:
  name: openai-apikey
  namespace: default
type: Opaque
stringData:
  apiKey: sk-proj-xxxxxxxxxxxxxxxxxxxx
```

---

## Verification & Troubleshooting

### Check Resource Status

```bash
# Check Envoy Gateway & AI Gateway pods
kubectl get pods -n envoy-gateway-system
kubectl get pods -n envoy-ai-gateway-system

# Check Gateway & Route statuses
kubectl get gateway,aigatewayroute,aiservicebackend,backend -A
```

### Inspect Envoy Access Logs

```bash
kubectl logs -n envoy-gateway-system deploy/envoy-default-envoy-ai-gateway-basic-21a9f8f8 -c envoy --tail=50 -f
```

### Common Issues

- **503 Service Unavailable / Connection Refused**:
  - Ensure LM Studio local server is started and listening on port `1234`.
  - In LM Studio settings, make sure CORS is enabled and network connections are allowed.
  - In local Kubernetes (Docker Desktop / Rancher Desktop / k3d), `host.docker.internal` is used to reach the host machine.
- **Client Buffer Limit Exceeded**:
  - LLM request/response payloads can exceed standard HTTP gateway buffer sizes. Ensure `ClientTrafficPolicy` with `bufferLimit: 50Mi` is applied to the Gateway.
