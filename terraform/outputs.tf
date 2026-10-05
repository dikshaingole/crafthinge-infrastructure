output "resource_group_name" { value = module.resource_group.name }
output "aks_name" { value = module.aks.name }
output "aks_node_resource_group" { value = module.aks.node_resource_group }
output "aks_oidc_issuer_url" { value = module.aks.oidc_issuer_url }
output "aks_kubelet_identity_object_id" { value = module.aks.kubelet_identity_object_id }
output "acr_login_server" { value = data.azurerm_container_registry.shared.login_server }
output "key_vault_name" { value = module.key_vault.name }
output "key_vault_uri" { value = module.key_vault.vault_uri }
output "appgw_public_ip" { value = module.application_gateway.public_ip_address }
output "appgw_fqdn" { value = module.application_gateway.fqdn }
output "postgres_fqdn" { value = module.postgresql.fqdn }
output "service_bus_endpoint" { value = module.service_bus.endpoint }
output "log_analytics_workspace_id" { value = module.monitoring.log_analytics_workspace_id }
output "action_group_id" { value = module.monitoring.action_group_id }

output "get_credentials_command" {
  value = "az aks get-credentials -g ${module.resource_group.name} -n ${module.aks.name} && kubelogin convert-kubeconfig -l azurecli"
}
