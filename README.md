# crafthinge-infrastructure

Terraform and the Azure DevOps infrastructure pipeline for **CraftHinge**, a fictional food ordering & delivery platform built as an end-to-end Azure DevOps / GitOps portfolio project.

> Infrastructure CI/CD: **GitHub → Azure DevOps → Terraform → Azure**
> Application CI/CD (other repos): **GitHub → Azure DevOps → Docker → ACR → GitOps repo → Argo CD → AKS**

## What this repo creates
| Stack | Resources |
|---|---|
| `terraform/shared` | `rg-crafthinge-shared`, Terraform state storage account, ACR `crafthingeacr` |
| `terraform` (per env) | Resource group, VNet + 4 subnets + NSGs, AKS (system + apps pools, AGIC, Workload Identity, Container Insights, Key Vault CSI), Application Gateway v2 / WAF, Key Vault, PostgreSQL Flexible Server (6 DBs), Service Bus, Log Analytics + App Insights + action group, diagnostic settings, role assignments |

## Layout
```
├── terraform/            shared stack, env stack, modules, tfvars, backend configs
├── pipelines/            terraform-pipeline.yml + templates + scripts (OIDC auth)
├── scripts/              GitHub rulesets, destroy helper
└── docs/
    ├── 01-foundation.md      architecture, repos, branching, branch protection
    ├── 02-terraform.md       modules, networking, setup, pipeline, verification
    └── terraform-state.md    remote state, locking, security, recovery
```

## Quick start
1. Bootstrap shared stack locally → migrate its state ([docs/02-terraform.md §3.2](docs/02-terraform.md))
2. Create Azure DevOps service connections + environments with approvals (§3.3)
3. Apply GitHub rulesets: `OWNER=<you> ./scripts/github-branch-protection.sh`
4. Run the pipeline for `dev`

## Roadmap
- [x] Phase 1: Foundation
- [x] Phase 2: Terraform + infrastructure pipeline
- [x] Phase 3: Spring Boot microservices + frontend + Dockerfiles (runs locally with Docker Compose)
- [ ] Phase 4: Application CI pipeline (Sonar, Trivy, ACR push, GitOps update)
- [ ] Phase 5: Helm charts, Argo CD, ApplicationSet
- [ ] Phase 6: Workload Identity, Key Vault CSI, TLS, NetworkPolicies, RBAC
- [ ] Phase 7: Monitoring, Prometheus/Grafana, alerts, promotion & rollback
- [ ] Phase 8: Troubleshooting runbook, interview guide
