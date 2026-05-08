# Alpine Normal Deployment

This folder contains plain Kubernetes deployments for demoing the difference between normal manifests and Kustomize.

Unlike the nginx Kustomize example, SIT and UAT are separate full manifest files here.

## Apply

```bash
kubectl apply -f alpine/sit/deployment.yaml
kubectl apply -f alpine/uat/deployment.yaml
```

## Check

```bash
kubectl get pods -n alpine-sit
kubectl logs -n alpine-sit deploy/alpine-sit

kubectl get pods -n alpine-uat
kubectl logs -n alpine-uat deploy/alpine-uat
```

## Remove

```bash
kubectl delete -f alpine/sit/deployment.yaml
kubectl delete -f alpine/uat/deployment.yaml
```
