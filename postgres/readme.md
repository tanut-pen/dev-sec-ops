# Postgres Local Lab

Installs PostgreSQL using the Bitnami Helm chart.

## Details

- **Namespace**: `postgres`
- **Chart**: `bitnami/postgresql`
- **Service Type**: `NodePort` on port `30432`
- **Persistence**: `8Gi`

## Credentials

- **Username**: `admin`
- **Password**: `admin`
- **Database**: `postgres`

## Installation

```bash
./install.sh
```
