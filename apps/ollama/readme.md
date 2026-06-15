# Ollama — Local LLM Server

Runs [Ollama](https://ollama.com) as a Kubernetes Deployment, serving **Qwen3 0.6B** for use with LiteLLM.

## Details

- **Namespace**: `ollama`
- **Image**: `ollama/ollama:latest` (Docker Hub)
- **Model**: `qwen3:0.6b` (auto-pulled on pod start)
- **Service Type**: `NodePort` on port `30435`
- **Cluster endpoint**: `http://ollama.ollama.svc.cluster.local:11434`

## Installation

```bash
./install.sh
```

## LiteLLM Integration

LiteLLM connects to Ollama via the in-cluster service URL.
Model is configured as `ollama/qwen3:0.6b` in LiteLLM's model list (stored in DB via admin UI).

## Adding More Models

```bash
kubectl exec -n ollama deploy/ollama -- ollama pull <model-name>
```
