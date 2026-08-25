# Rancher Manager with Docker Compose

This guide runs Rancher Manager outside the RKE2 cluster in Docker Compose. The RKE2 cluster remains in the Vagrant VMs and is registered as a downstream cluster:

```text
Docker Compose (Rancher Manager) -> RKE2 cluster in VMs
```

The steps are adapted from the [Rancher Manager Helm CLI quick start](https://ranchermanager.docs.rancher.com/v2.15/getting-started/quick-start-guides/deploy-rancher-manager/helm-cli). The Compose method is intended for local simulation only. Rancher’s supported production deployment uses Kubernetes.

> [!WARNING]
> This proof-of-concept uses one RKE2 server and the Rancher container’s built-in self-signed certificate. Use a highly available Kubernetes deployment, a real DNS name, a load balancer, and trusted certificates for production.

## Prerequisites

Complete the RKE2 setup through Step 3 in [README.md](README.md). The master must have a working `kubectl` configuration and all expected nodes must be Ready:

```bash
cd vm
vagrant ssh rke2-master
kubectl get nodes
```

Install Docker Desktop or Docker Engine with the Compose plugin on the machine that will run Rancher:

```bash
docker version
docker compose version
```

The Docker host must be able to reach `192.168.56.10`, and the RKE2 nodes must be able to reach the Docker host’s Rancher URL. Docker Desktop on macOS may not route directly to VMware host-only networks; test this before registering the cluster.

## 1. Start Rancher Manager

From the repository root, start the external Rancher container:

```bash
cd vm
export RANCHER_VERSION='<RANCHER_VERSION>'
docker compose -f rancher-manager.compose.yaml up -d
docker compose -f rancher-manager.compose.yaml logs -f rancher
```

Set `RANCHER_VERSION` to a Rancher version compatible with this lab’s Kubernetes version. If it is omitted, the Compose file uses `latest`.

Wait until the logs indicate that Rancher is ready, then open Rancher from the local workstation:

```text
https://localhost
```

For access from another machine, replace `localhost` with the Docker host’s reachable IP or DNS name. Because this installation uses a self-signed certificate, the browser will show a certificate warning.

## 2. Get the initial password

The first-run password is printed in the Rancher container logs. Retrieve it with:

```bash
docker compose -f rancher-manager.compose.yaml logs rancher | grep 'Bootstrap Password:'
```

Sign in with username `admin`. Change the password when Rancher prompts you. The password is stored in the named `rancher_data` volume and is not configured in this repository.

## 3. Register the RKE2 cluster

In the Rancher UI:

1. Select **Cluster Management**.
2. Select **Import Existing**.
3. Enter a name such as `rke2-vagrant` and create the cluster.
4. Copy the generated registration command.
5. Run that command on the `rke2-master` VM, where `kubectl` uses the RKE2 kubeconfig.

```bash
vagrant ssh rke2-master
kubectl get nodes
# Paste the registration command from Rancher here
```

The registration command must use a Rancher URL reachable from the VM, not `https://localhost`. If Rancher runs on the local Mac, use the Mac’s reachable IP or DNS name. Ensure the VM can resolve and connect to Rancher on TCP port `443`.

Verify registration from the master:

```bash
kubectl get pods -A
kubectl get namespaces
```

The Rancher UI should eventually show the imported cluster as **Active**. Imported clusters receive Rancher agents in the RKE2 cluster; Rancher itself remains in Docker Compose.

## Troubleshooting connectivity

From the RKE2 master, test the Rancher endpoint used by the registration command:

```bash
curl -kI https://<DOCKER_HOST_IP>
nc -vz <DOCKER_HOST_IP> 443
kubectl get pods -A | grep cattle
```

If these commands fail, fix routing or firewall rules before rerunning the registration command. The Docker host and the VM must be mutually reachable; publishing ports on Docker does not automatically make a VMware host-only network reachable from Docker Desktop.

## Stop and remove Rancher

```bash
docker compose -f rancher-manager.compose.yaml down
```

To delete Rancher data as well, remove the named volume:

```bash
docker compose -f rancher-manager.compose.yaml down -v
```

For complete installation requirements and upgrade options, see the [Rancher Manager documentation](https://ranchermanager.docs.rancher.com/v2.15/).
