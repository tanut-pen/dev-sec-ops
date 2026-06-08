# MySQL Local Lab

Installs MySQL using the Bitnami Helm chart.

## Details

- **Namespace**: `dongtai`
- **Chart**: `bitnami/mysql`
- **Service Type**: `NodePort` on port `30306`
- **Persistence**: `8Gi`

## Credentials

- **Root Password**: `dongtai-iast`
- **Username**: `root`
- **Password**: `dongtai-iast`
- **Database**: `dongtai_webapi`

## Installation

```bash
chmod +x install.sh
./install.sh
```

## Connection

```bash
mysql -h <node-ip> -P 30306 -u root -p dongtai_webapi
```
