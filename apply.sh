#!/bin/bash
set -e

#install argocd
./argocd/install.sh

#applt app-of-app
kubectl apply -f argocd/app-of-apps.yaml

#apply postgres
./postgres/install.sh
