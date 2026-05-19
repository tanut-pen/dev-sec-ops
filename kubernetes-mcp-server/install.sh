#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

helm upgrade --install kubernetes-mcp-server \
  oci://ghcr.io/containers/charts/kubernetes-mcp-server \
  --version 0.1.0 \
  --namespace kubernetes-mcp-server \
  --create-namespace \
  -f "${SCRIPT_DIR}/values.yaml"

echo "Kubernetes MCP server deployed in namespace kubernetes-mcp-server."
echo "  SSE (in-cluster):  http://kubernetes-mcp-server.kubernetes-mcp-server.svc.cluster.local:8080/sse"
echo "  MCP HTTP:          http://kubernetes-mcp-server.kubernetes-mcp-server.svc.cluster.local:8080/mcp"
echo "  SSE (ingress):     https://mcp-kube.tpinf.xyz/sse"
