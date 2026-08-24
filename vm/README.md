# RKE2 Multi-Node Cluster Lab (VMware Fusion / Vagrant)

A beginner-friendly guide to setting up a multi-node Linux environment with Vagrant and manually installing **RKE2 (Rancher Kubernetes Engine 2)** following the [Official RKE2 Quickstart Documentation](https://docs.rke2.io/install/quickstart).

---

## 📋 Table of Contents
1. [Cluster Overview & IP Plan](#-cluster-overview--ip-plan)
2. [Step 0: Start the Virtual Machines](#-step-0-start-the-virtual-machines)
3. [Step 1: Install RKE2 Server (Master Node)](#-step-1-install-rke2-server-master-node)
4. [Step 2: Install RKE2 Agent (Worker Nodes)](#-step-2-install-rke2-agent-worker-nodes)
5. [Step 3: Verify the Cluster](#-step-3-verify-the-cluster)
6. [🛠 Helpful Commands & Troubleshooting](#-helpful-commands--troubleshooting)

---

## 🏗 Cluster Overview & IP Plan

| Node Name | Role | IP Address | vCPU | RAM | Service Name |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`rke2-master`** | Server (Control Plane + etcd) | `192.168.56.10` | 2 | 4096 MB | `rke2-server` |
| **`rke2-worker-1`** | Agent (Worker Node) | `192.168.56.20` | 2 | 2048 MB | `rke2-agent` |
| **`rke2-worker-2`** | Agent (Worker Node) | `192.168.56.21` | 2 | 2048 MB | `rke2-agent` |

> [!NOTE]
> All VMs are pre-configured with swap disabled and `/etc/hosts` resolution enabled.

---

## 🚀 Step 0: Start the Virtual Machines

Navigate to the `vm` directory and start your machines using VMware Fusion:

```bash
cd vm
vagrant up --provider=vmware_desktop
```

Check that all 3 VMs are running:
```bash
vagrant status
```

---

## 👑 Step 1: Install RKE2 Server (Master Node)

### 1.1 Connect to the Master Node
```bash
vagrant ssh rke2-master
```

### 1.2 (Optional but Recommended) Create Server Configuration
Create the config directory and specify the node IP and TLS SANs:
```bash
sudo mkdir -p /etc/rancher/rke2/
sudo tee /etc/rancher/rke2/config.yaml > /dev/null <<EOF
write-kubeconfig-mode: "0644"
tls-san:
  - "192.168.56.10"
  - "rke2-master"
EOF
```

### 1.3 Run the Installer
Run the official RKE2 installation script:
```bash
curl -sfL https://get.rke2.io | sudo sh -
```

### 1.4 Enable and Start the `rke2-server` Service
```bash
sudo systemctl enable rke2-server.service
sudo systemctl start rke2-server.service
```

> [!TIP]
> Starting RKE2 for the first time downloads container images and initializes etcd. This takes **1 to 2 minutes**.
> You can monitor startup progress in real-time:
> ```bash
> sudo journalctl -u rke2-server -f
> ```
> Press `Ctrl+C` when you see initialization logs completing.

### 1.5 Set up `kubectl` Access
By default, RKE2 installs CLI tools in `/var/lib/rancher/rke2/bin/`. Let's add them to your `PATH` and set up `kubeconfig`:

```bash
# Add RKE2 binaries to PATH
echo 'export PATH=$PATH:/var/lib/rancher/rke2/bin' >> ~/.bashrc
export PATH=$PATH:/var/lib/rancher/rke2/bin

# Set KUBECONFIG for the current user
mkdir -p ~/.kube
sudo cp /etc/rancher/rke2/rke2.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# Add alias for convenience
echo "alias k='kubectl'" >> ~/.bashrc
```

Verify that the master node is Ready:
```bash
kubectl get nodes
```

### 1.6 Get the Registration Token
You need this token to join worker nodes to the cluster:
```bash
sudo cat /var/lib/rancher/rke2/server/node-token
```
> Copy the output token (it starts with `K10...`). You will need it in **Step 2**.

---

## 👷 Step 2: Install RKE2 Agent (Worker Nodes)

Perform these steps on **both** `rke2-worker-1` and `rke2-worker-2`.

### 2.1 Connect to the Worker Node
Open a new terminal tab or exit the master node, then SSH into the worker:
```bash
vagrant ssh rke2-worker-1
```

### 2.2 Run the Agent Installer
Install RKE2 with `INSTALL_RKE2_TYPE="agent"`:
```bash
curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_TYPE="agent" sh -
```

### 2.3 Enable the `rke2-agent` Service
```bash
sudo systemctl enable rke2-agent.service
```

### 2.4 Configure the Agent Service
Create `/etc/rancher/rke2/config.yaml` pointing to the master node:

```bash
sudo mkdir -p /etc/rancher/rke2/
sudo nano /etc/rancher/rke2/config.yaml
# Or use tee:
```

Paste the following content (replace `<YOUR_NODE_TOKEN>` with the token from Step 1.6):

```yaml
server: https://192.168.56.10:9345
token: <YOUR_NODE_TOKEN>
```

> [!IMPORTANT]
> The `rke2 server` process listens on port **`9345`** for worker node registration (the Kubernetes API is on `6443`).

### 2.5 Start the `rke2-agent` Service
```bash
sudo systemctl start rke2-agent.service
```

> [!TIP]
> You can follow agent logs using:
> ```bash
> sudo journalctl -u rke2-agent -f
> ```

---

> Repeat **Step 2** on `rke2-worker-2` (`vagrant ssh rke2-worker-2`).

---

## ✅ Step 3: Verify the Cluster

Log back into your master node:
```bash
vagrant ssh rke2-master
```

Check your nodes:
```bash
kubectl get nodes -o wide
```

You should see all 3 nodes with status **`Ready`**:
```text
NAME            STATUS   ROLES                       AGE     VERSION
rke2-master     Ready    control-plane,etcd,master   5m      v1.30.x+rke2r1
rke2-worker-1   Ready    <none>                      2m      v1.30.x+rke2r1
rke2-worker-2   Ready    <none>                      1m      v1.30.x+rke2r1
```

Check all system pods:
```bash
kubectl get pods -A
```

---

## 🛠 Helpful Commands & Troubleshooting

### VM Management
| Task | Command (from host `vm/` directory) |
| :--- | :--- |
| **Check VM Status** | `vagrant status` |
| **SSH into Master** | `vagrant ssh rke2-master` |
| **SSH into Worker 1** | `vagrant ssh rke2-worker-1` |
| **SSH into Worker 2** | `vagrant ssh rke2-worker-2` |
| **Pause VMs (Save State)** | `vagrant suspend` |
| **Stop VMs (Shutdown)** | `vagrant halt` |
| **Delete & Reset Everything** | `vagrant destroy -f` |

### RKE2 Troubleshooting Commands
- **Check service status on node:**
  - Master: `sudo systemctl status rke2-server`
  - Worker: `sudo systemctl status rke2-agent`
- **View live logs:**
  - Master: `sudo journalctl -u rke2-server -f`
  - Worker: `sudo journalctl -u rke2-agent -f`
- **Uninstall RKE2 (if you want to start over on a node):**
  - Master: `sudo /usr/local/bin/rke2-uninstall.sh`
  - Worker: `sudo /usr/local/bin/rke2-agent-uninstall.sh`
