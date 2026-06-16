#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

kubectl apply -k "${SCRIPT_DIR}"

echo "MCP Jenkins deployed in namespace jenkins."
echo "  SSE (in-cluster):  http://mcp-jenkins.jenkins.svc.cluster.local:9887/sse"
echo "  SSE (NodePort):      http://localhost:30434/sse"
echo "  SSE (ingress):       https://mcp-jenkins.tpinf.xyz/sse"
