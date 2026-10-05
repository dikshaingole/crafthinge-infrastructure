# Hardened storage account for Terraform state:
#  - no shared keys (Entra ID + RBAC only), TLS 1.2, no public blobs
#  - versioning + soft delete so a corrupted/deleted state file can be restored
#  - CanNotDelete lock so nobody removes the account by accident
resource "azurerm_storage_account" "this" {
  name                              = var.name
  resource_group_name               = var.resource_group_name
  location                          = var.location
  account_tier                      = "Standard"
  account_replication_type          = var.replication_type
  min_tls_version                   = "TLS1_2"
  https_traffic_only_enabled        = true
  shared_access_key_enabled         = false
  allow_nested_items_to_be_public   = false
  infrastructure_encryption_enabled = true
  public_network_access_enabled     = var.public_network_access_enabled

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = var.soft_delete_retention_days
    }
    container_delete_retention_policy {
      days = var.soft_delete_retention_days
    }
  }

  tags = var.tags
}

# storage_account_id => created via the management plane (works with shared keys disabled)
resource "azurerm_storage_container" "this" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "blob_data_contributor" {
  for_each             = toset(var.blob_data_contributor_principal_ids)
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}

resource "azurerm_management_lock" "this" {
  count      = var.enable_delete_lock ? 1 : 0
  name       = "lock-${var.name}"
  scope      = azurerm_storage_account.this.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state. Remove deliberately, never by accident."
}
