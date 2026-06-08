# SonarQube

## What Is This Tool

SonarQube is a code quality and static application security analysis platform. It scans source code and reports bugs, code smells, duplicated code, and some security issues.

In this project, SonarQube is used to analyze the application source code during the Jenkins pipeline.

## How It Works

This folder contains:

- `install.sh` to install SonarQube on Kubernetes
- `values-sonar.yaml` for chart configuration

In this repo, Jenkins runs SonarQube analysis by calling `sonar-scanner` and sending source paths from:

- `backend`
- `client`

The pipeline points to the in-cluster SonarQube service:

```text
http://sonarqube-sonarqube.sonarqube.svc.cluster.local:9000
```

## When We Need It

Use SonarQube when you need:

- source code quality checks
- static code analysis in CI
- early detection of code issues before deployment
- a dashboard for code health over time

## How To Apply To Kubernetes Cluster

### Prerequisites

- Kubernetes cluster is running
- `helm` is installed

### Add The Helm Repository

```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
```

### Install SonarQube

From this folder:

```bash
kubectl create namespace sonarqube
export MONITORING_PASSCODE="admin123"
helm upgrade --install -n sonarqube sonarqube sonarqube/sonarqube --set community.enabled=true,monitoringPasscode=$MONITORING_PASSCODE
```

Or run:

```bash
./install.sh
```

### Current Settings In This Repo

- Namespace: `sonarqube`
- Community mode enabled
- Monitoring passcode: `admin123`

### Optional Values File

This repo also includes `values-sonar.yaml`, but the current `install.sh` does not use it.

If you want to apply the values file instead, use:

```bash
helm upgrade --install sonarqube sonarqube/sonarqube -n sonarqube --create-namespace -f values-sonar.yaml
```

## Notes

- `token.md` contains a token in plain text. That should be moved to a secure secret store or Jenkins credential.
- The current install approach uses inline `--set` parameters instead of the provided values file.
