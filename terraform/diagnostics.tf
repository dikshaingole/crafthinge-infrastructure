# Platform logs that are NOT collected by default.

# AKS control plane: API server + audit (who changed what), autoscaler decisions.
resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                           = "diag-aks"
  target_resource_id             = module.aks.id
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "kube-apiserver" }
  enabled_log { category = "kube-audit-admin" } # writes only: cheaper than full kube-audit
  enabled_log { category = "cluster-autoscaler" }
  enabled_log { category = "guard" }            # Entra ID authN/authZ decisions
}

# App Gateway: access log (status codes, latency per backend) + WAF log.
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                           = "diag-appgw"
  target_resource_id             = module.application_gateway.id
  log_analytics_workspace_id     = module.monitoring.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  enabled_log { category = "ApplicationGatewayAccessLog" }
  enabled_log { category = "ApplicationGatewayFirewallLog" }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                       = "diag-kv"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.monitoring.log_analytics_workspace_id

  enabled_log { category = "AuditEvent" } # every secret read is traceable
}
