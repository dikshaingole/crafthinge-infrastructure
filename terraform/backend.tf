# Remote state in the shared storage account (created by terraform/shared).
# Partial configuration: the per-environment values live in backends/<env>.hcl
#   terraform init -backend-config=backends/dev.hcl
# Locking is automatic: the azurerm backend takes a blob lease on the state file.
terraform {
  backend "azurerm" {
    use_azuread_auth = true # Entra ID + RBAC, no storage account keys
  }
}
