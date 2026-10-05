# All cross-module permissions in one place, so "who can do what" is easy to review.

# AKS nodes pull images from the shared ACR with their managed identity.
# No registry passwords, no imagePullSecrets.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = data.azurerm_container_registry.shared.id
  role_definition_name             = "AcrPull"
  principal_id                     = module.aks.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

# AGIC (running in AKS) reconfigures App Gateway from Ingress objects.
resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = module.application_gateway.id
  role_definition_name = "Contributor"
  principal_id         = module.aks.agic_identity_object_id
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = module.resource_group.id
  role_definition_name = "Reader"
  principal_id         = module.aks.agic_identity_object_id
}

resource "azurerm_role_assignment" "agic_appgw_subnet" {
  scope                = module.networking.appgw_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = module.aks.agic_identity_object_id
}

# Humans: Entra groups get cluster-admin via Azure RBAC (no local accounts).
resource "azurerm_role_assignment" "aks_cluster_admins" {
  for_each             = toset(var.aks_admin_group_object_ids)
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = each.value
}

# Read-only engineers (optional).
resource "azurerm_role_assignment" "aks_readers" {
  for_each             = toset(var.aks_reader_group_object_ids)
  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  principal_id         = each.value
}
