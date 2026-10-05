# DEV: cheapest setup that still exercises every component.
environment        = "dev"
location           = "eastus2"
availability_zones = null

vnet_address_space = ["10.0.0.0/16"]
subnet_prefixes = {
  aks               = "10.0.0.0/20"
  appgw             = "10.0.16.0/24"
  private_endpoints = "10.0.17.0/24"
  postgres          = "10.0.18.0/24"
}

aks_sku_tier         = "Free"
aks_system_node_pool = { vm_size = "Standard_D2s_v5", min_count = 1, max_count = 2 }
aks_user_node_pool   = { vm_size = "Standard_D4s_v5", min_count = 1, max_count = 3 }

# az ad group show --group "crafthinge-aks-admins" --query id -o tsv
aks_admin_group_object_ids   = ["00000000-0000-0000-0000-000000000000"]
aks_api_authorized_ip_ranges = []

appgw_sku          = "Standard_v2"
appgw_min_capacity = 0
appgw_max_capacity = 2

kv_purge_protection_enabled = false
kv_network_default_action   = "Allow"

postgres_sku_name          = "B_Standard_B1ms"
postgres_high_availability = false

log_retention_days = 30
log_daily_quota_gb = 2
alert_emails       = ["you@example.com"]

tags = { owner = "platform-team", cost_center = "crafthinge" }
