# Phase 2: Infrastructure with Terraform

## 1. Stacks and modules

```
terraform/
├── shared/                 stack 1: state storage + ACR (applied once, rarely changes)
├── versions.tf providers.tf backend.tf main.tf iam.tf diagnostics.tf
├── variables.tf outputs.tf locals.tf          stack 2: one environment (dev | qa | prod)
├── environments/{dev,qa,prod}.tfvars          ← the only difference between environments
├── backends/{dev,qa,prod}.hcl                 ← which state file each environment uses
└── modules/
    resource-group  networking  aks  acr  key-vault  application-gateway
    monitoring  storage  postgresql  service-bus
```

`environments/<env>.tfvars` plays the role of `terraform.tfvars`. Using named files means nobody can accidentally apply dev values to prod: the pipeline always passes `-var-file` explicitly.

| Module | Why it exists | Key decisions |
|---|---|---|
| resource-group | Lifecycle + RBAC boundary per environment | `prevent_deletion_if_contains_resources` |
| networking | Isolation and traffic control | 4 subnets, NSG per subnet, Postgres subnet delegated |
| aks | Runs everything | System/user pools, Azure CNI + Calico, Entra RBAC, local accounts off, OIDC + Workload Identity, AGIC, Container Insights, Key Vault CSI, Azure Policy, auto patch upgrades |
| acr | Image store | Shared across envs (build once, promote), admin user off, AcrPush/AcrPull via RBAC |
| key-vault | Secrets | RBAC mode, soft delete, purge protection + private endpoint in prod |
| application-gateway | Single public entry point | v2 autoscaling, TLS 1.2+ policy, WAF (OWASP 3.2) in qa/prod, AGIC owns routing (`ignore_changes`) |
| monitoring | Observability | Log Analytics + App Insights + action group |
| storage | Terraform state | No shared keys, versioning, soft delete, lock |
| postgresql | Data | One server, 7 DBs (one per service), VNet-only, zone-redundant HA in prod |
| service-bus | Async order events | Topic `order-events` → subscriptions for notification & delivery; local auth off |

Cross-module permissions live in **`iam.tf`** so security review is one file:

| Identity | Role | Scope | Why |
|---|---|---|---|
| AKS control plane (UAI) | Network Contributor | AKS subnet | Manage LB/NIC in a custom VNet |
| AKS kubelet | AcrPull | shared ACR | Pull images without passwords |
| AGIC add-on | Contributor / Reader / Network Contributor | App Gateway / RG / AppGW subnet | Write routes from Ingress objects |
| App Gateway (UAI) | Key Vault Secrets User | Key Vault | Read TLS cert (Phase 6) |
| Terraform pipeline | Key Vault Secrets Officer | Key Vault | Write generated secrets |
| CI pipeline | AcrPush | shared ACR | Push images (nothing else) |
| Admin Entra group | AKS RBAC Cluster Admin | AKS | Human access, audited via `guard` logs |

## 2. Networking explained

| Layer | Range | Notes |
|---|---|---|
| VNet | 10.0.0.0/16 (dev) | qa 10.1, prod 10.2 |
| Node + pod IPs | snet-aks 10.0.0.0/20 | **Azure CNI**: each pod gets a real VNet IP. Required so App Gateway (AGIC) can send traffic straight to pod IPs. Capacity: `max_pods` 30 (system) / 50 (apps) + 1 per node, so a /20 fits ~75+ nodes |
| Kubernetes Services | 172.16.0.0/16 | Virtual IPs, never on the wire; must not overlap any VNet |
| Cluster DNS | 172.16.0.10 | CoreDNS. `http://order-service.crafthinge.svc.cluster.local` (or just `order-service` within the namespace) |
| App Gateway | snet-appgw /24 | Dedicated subnet (Azure requirement) |
| Postgres | snet-postgres /24 | Delegated; private DNS zone resolves the server name to a private IP |
| Private endpoints | snet-private-endpoints /24 | Key Vault in prod |

Traffic rules (NSGs):
- **Internet → App Gateway** on 80/443 only (+ GatewayManager/AzureLoadBalancer platform rules).
- **App Gateway → AKS subnet** allowed; **Internet → AKS** explicitly denied. No microservice gets a public IP or `LoadBalancer` Service.
- **AKS → Postgres:5432** allowed; any other VNet source → 5432 denied.
- Inside the cluster, Kubernetes **NetworkPolicies** (Calico) restrict pod-to-pod traffic (Phase 6), e.g. only order-service may call payment-service.

## 3. One-time setup

### 3.1 Prerequisites
- Azure subscription where you're Owner (needed to create role assignments)
- Terraform ≥ 1.9, Azure CLI, `kubelogin`, `gh`
- An Entra ID group for cluster admins: `az ad group create --display-name crafthinge-aks-admins --mail-nickname crafthinge-aks-admins` and add yourself. Put its ID in `aks_admin_group_object_ids`.

### 3.2 Bootstrap the shared stack (from your laptop, once)
```bash
az login
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
cd terraform/shared
terraform init
terraform apply -var-file=shared.tfvars
terraform output tfstate_storage_account_name    # copy this
# 1) paste it into shared/backend.hcl and ../backends/*.hcl
# 2) uncomment the backend block in shared/backend.tf
terraform init -migrate-state -backend-config=backend.hcl
rm -f terraform.tfstate terraform.tfstate.backup
```
If `crafthingeacr` is taken globally, set another `acr_name` (and `shared_acr_name` in the env tfvars).

### 3.3 Azure DevOps
1. **Project** `CraftHinge`.
2. **Service connections** → *Azure Resource Manager* → *Workload identity federation (automatic)*, one per stack: `sc-crafthinge-shared`, `sc-crafthinge-dev`, `sc-crafthinge-qa`, `sc-crafthinge-prod`. Grant each **Owner** (or Contributor + User Access Administrator, since Terraform creates role assignments) on its subscription. Prod's connection should only reach the prod subscription.
3. Copy each connection's service principal object ID into `terraform_pipeline_principal_ids` in `shared/shared.tfvars` and re-apply shared, so they get state access.
4. **Environments** → create `crafthinge-infra-dev`, `-qa`, `-prod`, `-shared`. Under *Approvals and checks* add **Approvals** (prod: 2 approvers, "requester cannot approve") and optionally *Business hours*.
5. **GitHub connection**: install the Azure Pipelines GitHub App on `crafthinge-infrastructure`.
6. **Pipelines** → New → GitHub → `crafthinge-infrastructure` → *Existing YAML* → `/pipelines/terraform-pipeline.yml`. Name it `crafthinge-infra-terraform` (the branch-protection check name).

### 3.4 Run it
- Open a PR that touches `terraform/` → Validate + Plan run, and the check appears on the PR.
- Merge → Plan → **approval** (review `tfplan.txt` in the run's artifacts) → Apply to dev.
- QA/PROD: *Run pipeline* → choose stack.

## 4. Pipeline stages

```
Validate ──► Plan ──► (approval on environment) ──► Apply
fmt -check    init (OIDC)        human reviews        apply EXACTLY the saved
init -backend=false  plan -out   tfplan.txt           plan file; refuses if
validate      detailed-exitcode                       state changed since
Trivy IaC     publish artifact
```

- **No secrets in the pipeline:** Workload Identity Federation means Azure trusts a short-lived token issued by Azure DevOps for that one service connection. There is no client secret to leak or rotate.
- **Plan/apply integrity:** the approver approves a specific plan file; `terraform apply tfplan` applies that and nothing else.
- **No-op runs skip the approval:** `-detailed-exitcode` sets `hasChanges=false`, so the Apply stage is skipped.
- **Pinned versions:** Terraform version in the pipeline, provider versions in `.terraform.lock.hcl` (commit it after your first `terraform init`).
- **Security gate:** Trivy IaC scan; CRITICAL findings fail the build, HIGH are reported.

## 5. Verify after the first dev apply
```bash
terraform output
$(terraform output -raw get_credentials_command)
kubectl get nodes -L kubernetes.azure.com/agentpool,topology.kubernetes.io/zone
kubectl get pods -n kube-system | grep -E 'ingress-appgw|ama-|secrets-store|coredns'
az acr check-health -n crafthingeacr --yes
az aks check-acr -g rg-crafthinge-dev -n aks-crafthinge-dev --acr crafthingeacr.azurecr.io
```
Expected: 2+ nodes in `system` and `apps` pools; AGIC (`ingress-appgw-deployment`), Azure Monitor agents (`ama-*`) and the CSI driver running; ACR check succeeds.

## 6. Cost control
AKS nodes, App Gateway v2 and Postgres bill hourly even when idle. When not practising:
```bash
./scripts/destroy-env.sh dev       # keeps shared stack (state + ACR)
```
Recreate later with the pipeline. Images in ACR survive, so Argo CD redeploys the same versions.
