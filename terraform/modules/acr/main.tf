# One shared registry for all environments: an image is built ONCE and the
# same digest is promoted DEV -> QA -> PROD. Admin user is disabled; access is
# RBAC only (AcrPush for CI, AcrPull for each AKS kubelet identity).
resource "azurerm_container_registry" "this" {
  name                    = var.name
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku                     = var.sku
  admin_enabled           = false
  anonymous_pull_enabled  = false
  zone_redundancy_enabled = var.sku == "Premium" ? var.zone_redundancy_enabled : false
  tags                    = var.tags
}

resource "azurerm_role_assignment" "push" {
  for_each             = toset(var.push_principal_ids)
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPush"
  principal_id         = each.value
}
