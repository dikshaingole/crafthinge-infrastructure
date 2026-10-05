output "vnet_id" { value = azurerm_virtual_network.this.id }
output "vnet_name" { value = azurerm_virtual_network.this.name }
output "aks_subnet_id" { value = azurerm_subnet.aks.id }
output "appgw_subnet_id" { value = azurerm_subnet.appgw.id }
output "private_endpoints_subnet_id" { value = azurerm_subnet.private_endpoints.id }
output "postgres_subnet_id" { value = azurerm_subnet.postgres.id }
