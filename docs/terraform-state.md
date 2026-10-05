# Terraform remote state: design, locking, security, recovery

## Layout
```
Storage account sttfcrafthinge<suffix>  (rg-crafthinge-shared)
└── container: tfstate
    ├── shared/shared.tfstate   ← state storage itself + ACR
    ├── env/dev.tfstate
    ├── env/qa.tfstate
    └── env/prod.tfstate
```
One state file per stack keeps the blast radius small: a broken dev apply can't corrupt prod state, and plans stay fast.

## Bootstrap (chicken-and-egg)
The `shared` stack creates the storage account that will hold state, so its first apply uses local state, then migrates itself into the container it just created (`terraform init -migrate-state`). See `terraform/shared/backend.tf`.

## Locking
The `azurerm` backend takes a **blob lease** on the state file for the duration of plan/apply. A second run (another pipeline, a laptop) fails with `Error acquiring the state lock` instead of corrupting state. The pipeline uses `-lock-timeout=5m` to wait briefly rather than fail on short overlaps.
Stuck lock (agent killed mid-apply): confirm nothing is running, then `terraform force-unlock <LOCK_ID>` (ID is in the error), or break the lease in the portal.

## Security
State contains every attribute of every resource, **including secrets** (here: the Postgres admin password, App Insights connection string). So:

| Control | How |
|---|---|
| No account keys | `shared_access_key_enabled = false`; backend uses `use_azuread_auth = true` |
| Least privilege | Only the Terraform service connections + platform admins have *Storage Blob Data Contributor* |
| Encryption | Microsoft-managed keys + infrastructure (double) encryption; TLS 1.2+ |
| No anonymous access | `allow_nested_items_to_be_public = false` |
| Accidental deletion | `CanNotDelete` management lock |
| Plan files | Contain secrets too → kept as pipeline artifacts with project-scoped access, never posted in PR comments |
| Hardening option | Disable public network access and run Terraform from self-hosted agents inside a peered VNet |

## Recovery

| Problem | Fix |
|---|---|
| State file corrupted / bad apply wrote wrong state | Blob **versioning**: restore the previous version of `env/dev.tfstate` in the portal (or `az storage blob copy`) |
| State blob deleted | Blob **soft delete** (30 days): undelete |
| Container deleted | Container soft delete (30 days) |
| Region outage | GRS replica in the paired region (account failover) |
| Resource exists in Azure but not in state | `terraform import` (or an `import {}` block) |
| Resource renamed/moved in code | `terraform state mv` or a `moved {}` block, no destroy/recreate |
| Remove something from management without deleting it | `terraform state rm` (or a `removed {}` block) |
| Drift (someone clicked in the portal) | Nightly `terraform plan -detailed-exitcode`; exit code 2 = drift → alert |
