# LiteLLM Local Lab

Installs LiteLLM using a simple Kubernetes Deployment.

## Details

- **Namespace**: `litellm`
- **Image**: `harbor.local:30002/my-project/litellm:v1`
- **Service Type**: `NodePort` on port `30433`
- **Database**: Connects to the local Postgres service at `postgresql://admin:admin@postgres-postgresql.postgres.svc.cluster.local:5432/postgres`

## Installation

```bash
./install.sh
```
