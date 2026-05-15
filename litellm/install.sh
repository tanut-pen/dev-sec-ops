#!/usr/bin/env bash
set -euo pipefail

kubectl create namespace litellm --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -k . -n litellm
