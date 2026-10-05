# QA: production-like topology, smaller sizes.
environment        = "qa"
location           = "eastus2"
availability_zones = ["1", "2"]

vnet_address_space = ["10.1.0.0/16"]
subnet_prefixes = {
  aks               = "10.1.0.0/20"
  appgw             = "10.1.16.0/24"
  private_endpoints = "10.1.17.0/24"
  postgres          = "10.1.18.0/24"
}

aks_sku_tier         = "Free"
aks_system_node_pool = { vm_size = "Standard_D2s_v5", min_count = 2, max_count = 3 }
aks_user_node_pool   = { vm_size = "Standard_D4s_v5", min_count = 2, max_count = 4 }

aks_admin_group_object_ids   = ["00000000-0000-0000-0000-000000000000"]
aks_api_authorized_ip_ranges = []

appgw_sku          = "WAF_v2"
appgw_waf_mode     = "Detection"
appgw_min_capacity = 1
appgw_max_capacity = 3

kv_purge_protection_enabled = false
kv_network_default_action   = "Allow"

postgres_sku_name          = "B_Standard_B2s"
postgres_high_availability = false

log_retention_days = 30
alert_emails       = ["you@example.com"]

tags = { owner = "platform-team", cost_center = "crafthinge" }
