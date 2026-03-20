helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace -f values-argocd.yaml
helm upgrade --install argo-rollouts argo/argo-rollouts -n argo-rollouts --create-namespace -f values-rollouts.yaml
