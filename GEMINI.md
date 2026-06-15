# DevSecOps Lab — Agent Context

This repository provisions a local DevSecOps environment on Kubernetes (k3d).
It contains Helm values, Kustomize manifests, Argo CD Applications, and Jenkins
pipelines for a secure CI/CD lab with integrated scanning, monitoring, and GitOps delivery.

---

## Service Inventory

| Service | Namespace | Access | Purpose |
|---------|-----------|--------|---------|
| Jenkins | `jenkins` | `https://jenkins.tpinf.xyz` · NodePort `30003` | CI/CD orchestration |
| SonarQube | `sonarqube` | `sonarqube.local` | Static code analysis |
| Harbor | `harbor` | `http://localhost:30002` · `harbor.local` | Container image registry |
| DefectDojo | `defectdojo` | `defectdojo.local` | Vulnerability tracking |
| Argo CD | `argocd` | `argocd.local` · NodePort `30004` | GitOps delivery |
| Istio | `istio-system` / `istio-ingress` | NodePort `30080` (HTTP) / `30443` (HTTPS) | Service mesh & ingress |
| Grafana | `grafana` | `grafana.local` · NodePort `30005` | Monitoring dashboards |
| Grafana Alloy | `grafana-alloy` | — | Telemetry collection |
| Vault | `vault` | — | Secrets management |
| Kong | `kong` | `api.tpinf.xyz` · NodePort `30007`–`30009` | API gateway / ingress |
| Uptime Kuma | `monitoring` | NodePort `30006` | Uptime monitoring |
| Portainer | `portainer` | NodePort `30777` | Kubernetes UI management |
| LiteLLM | `litellm` | `litellm.tpinf.xyz` · NodePort `30433` | AI model proxy |
| Kubeseal | `kube-system` | — | Sealed Secrets controller |
| PostgreSQL | `postgres` | — | Database services |

---

## Repository Structure

```text
.
├── apps/                  # Service deployments (Helm values, Kustomize, install.sh)
├── argocd/                # Argo CD bootstrap
│   ├── app-list.yaml      # All Argo CD Application definitions (single source of truth)
│   └── app-of-apps.yaml   # Root bootstrap Application
├── static/                # Cluster-wide static resources (Ingress, RBAC)
│   └── ingress.yaml       # Shared Istio ingress rules (*.tpinf.xyz)
├── .agents/skills/        # AI agent skills
├── CLAUDE.md              # Token & credential reference (local lab use only)
├── GEMINI.md              # This file — agent context
└── skills-lock.json       # Skill registry with source hashes
```

### Key conventions

- **Ingress** goes in `static/` — not inside app Helm values or Kustomize dirs.
  The `static-manifest` Argo Application syncs `static/` with `directory.recurse: true`.
- **Argo CD Applications** are defined in `argocd/app-list.yaml` only — never create
  separate files. The root `app-of-apps` watches that single file.
- **Secrets** use `secret.yaml` (gitignored via `secret*.yaml` pattern). Never commit
  real credentials. Use `secret.yaml.example` as a committed template.
- **Helm services** follow: `apps/<service>/install.sh` + `<service>-values.yaml`.
- **Kustomize services** follow: `apps/<service>/kustomization.yaml` + `deployment.yaml` + `install.sh`.
- **Credential reference** is in `CLAUDE.md` (local lab only — do not commit real secrets).
- **Git repo URL** for Argo CD sources: `https://github.com/tanut-pen/dev-sec-ops.git`.

---

## MCP Tools Available

MCP server **`mcp-gateway-vayu`** provides tools for the following services.
Use `call_mcp_tool` with `ServerName: "mcp-gateway-vayu"`.

### Jenkins (`jenkins-*`)

| Tool | Purpose | Key Args |
|------|---------|----------|
| `jenkins-get_build` | Build info (result, duration, URL) | `fullname`, `number` (null = latest) |
| `jenkins-get_build_console_output` | Console logs with pattern search | `fullname`, `number`, `pattern`, `limit` |
| `jenkins-get_build_parameters` | Parameters used in a build | `fullname`, `number` |
| `jenkins-get_build_test_report` | Test results | `fullname`, `number` |
| `jenkins-get_running_builds` | Currently running builds | — |
| `jenkins-get_all_items` | List all jobs | — |
| `jenkins-query_items` | Search jobs by query | query filters |
| `jenkins-build_item` | ⚠️ Trigger a build (**confirm with user first**) | `fullname`, `build_type`, `params` |
| `jenkins-stop_build` | ⚠️ Stop a build (**confirm with user first**) | `fullname`, `number` |

### DefectDojo (`defectdojo-*`)

| Tool | Purpose | Key Args |
|------|---------|----------|
| `defectdojo-list_products` | Find products by name | `name`, `limit` |
| `defectdojo-get_product` | Product details | `product_id` |
| `defectdojo-get_findings` | Query findings (severity, active, product) | `severity`, `active`, `product_name`, `limit` |
| `defectdojo-get_finding` | Full detail for one finding | `finding_id` |
| `defectdojo-list_engagements` | Testing engagements | `product_id`, `status` |
| `defectdojo-list_tests` | Tests in an engagement | `engagement_id` |
| `defectdojo-get_test` | Test detail | `test_id` |
| `defectdojo-get_product_types` | Product type list | — |
| `defectdojo-list_test_types` | Test type list | — |
| `defectdojo-get_gitlab_url_from_product` | GitLab repo URL for a product | `product_id` |

### Harbor (`harbor-*`)

| Tool | Purpose | Key Args |
|------|---------|----------|
| `harbor-list_projects` | List all Harbor projects | — |
| `harbor-list_repositories` | Repos in a project | `project_name` |
| `harbor-list_artifacts` | Artifacts with scan info | `project_name`, `repository_name`, `tag` |
| `harbor-get_artifact_vulnerabilities` | CVE details for an artifact | `project_name`, `repository_name`, `reference` |

### GitLab (`gitlab_ro-*`) — Read-Only

| Tool | Purpose |
|------|---------|
| `gitlab_ro-search_repositories` | Search repos |
| `gitlab_ro-get_file_contents` | Read file from repo |
| `gitlab_ro-get_repository_tree` | Browse repo tree |
| `gitlab_ro-list_pipelines` / `get_pipeline` | CI/CD pipeline status |
| `gitlab_ro-list_merge_requests` / `get_merge_request` | MR details and diffs |
| `gitlab_ro-list_commits` / `get_commit` / `get_commit_diff` | Commit history |
| `gitlab_ro-list_issues` / `get_issue` | Issue tracking |
| `gitlab_ro-list_deployments` / `get_deployment` | Deployment history |
| `gitlab_ro-list_environments` / `get_environment` | Environment info |
| `gitlab_ro-list_pipeline_jobs` / `get_pipeline_job` | Job details & logs |
| `gitlab_ro-get_pipeline_job_output` | Job console output |

---

## Available Skills

Skills live in `.agents/skills/` and activate based on trigger patterns.

| Skill | Purpose | When to Use |
|-------|---------|-------------|
| `debug-jenkins` | Diagnose Jenkins build failures via MCP | Jenkins job failed, user shares build URL |
| `debug-mantra` | Four-step debugging discipline | Any debugging session — bugs, errors, stack traces |
| `dockerfile-best-practices` | Production-grade Dockerfiles | Writing, reviewing, or optimizing Dockerfiles |
| `kubernetes` | List pods, debug CrashLoopBackOff | Pod listing, namespace health, crash loops |
| `new-service-deployment` | Scaffold new service (Helm/Kustomize + Argo CD) | Adding a new app or tool to the lab |

---

## Safety Rules

- ⛔ **Never trigger builds** (`jenkins-build_item`) without explicit user confirmation.
- ⛔ **Never stop builds** (`jenkins-stop_build`) without explicit user confirmation.
- ⛔ **Never delete** Kubernetes resources without user approval.
- ⛔ **Never commit** `secret.yaml` or real credentials — they are gitignored.
- ⛔ **Never fabricate** data — always quote real output from MCP tools or commands.
- ⚠️ **Ask before** Argo CD syncs with prune enabled (risk of data loss).
- ⚠️ **Prefer MCP tools** over raw kubectl/curl; fall back to CLI only when MCP is unavailable.

---

## Pipeline Overview

The demo pipeline (`devsecops-demo-pipeline`) in `jenkins/demo/Jenkinsfile` runs:

1. Clone repo → 2. Install deps (Node.js) → 3. Run tests →
4. SonarQube analysis → 5. Build Docker image → 6. Trivy scan →
7. Push to Harbor (optional) → 8. Import to DefectDojo (optional)

Jenkins credentials required: `harbor-credentials`, `defectdojo-api-token`, `sonar`.
See `CLAUDE.md` for the full credential table.
