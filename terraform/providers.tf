# Authentication comes from the environment, never from this file:
#  - Laptop:   az login   + export ARM_SUBSCRIPTION_ID=...
#  - Pipeline: Workload Identity Federation (OIDC) env vars set by
#              pipelines/scripts/tf-env.sh
provider "azurerm" {
  storage_use_azuread = true

  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
  }
}
