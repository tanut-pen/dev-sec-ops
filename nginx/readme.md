# Nginx Kustomize Example

This folder contains a simple nginx deployment managed with Kustomize.

## Structure

```text
nginx/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/
    ├── sit/
    │   ├── kustomization.yaml
    │   ├── namespace.yaml
    │   └── resources-patch.yaml
    └── uat/
        ├── kustomization.yaml
        ├── namespace.yaml
        └── resources-patch.yaml
```

## Environments

- SIT namespace: `nginx-sit`
- SIT CPU request/limit: `256m`
- UAT namespace: `nginx-uat`
- UAT CPU request/limit: `512m`

## Render Manifests

```bash
kubectl kustomize nginx/overlays/sit
kubectl kustomize nginx/overlays/uat
```

## Apply

```bash
kubectl apply -k nginx/overlays/sit

kubectl apply -k nginx/overlays/uat
```
