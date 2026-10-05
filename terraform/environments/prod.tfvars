# PROD: separate cluster (ideally separate subscription), zone-redundant,
# WAF in Prevention, private Key Vault, HA database, locked-down API server.
environment        = "prod"
location           = "eastus2"
availability_zones = ["1", "2", "3"]

vnet_address_space = ["10.2.0.0/16"]
subnet_prefixes = {
  aks               = "10.2.0.0/20"
  appgw             = "10.2.16.0/24"
  private_endpoints = "10.2.17.0/24"
  postgres          = "10.2.18.0/24"
}

kubernetes_version   = null # pin to the version validated in QA, e.g. "1.31"
aks_sku_tier         = "Standard"
aks_system_node_pool = { vm_size = "Standard_D4s_v5", min_count = 3, max_count = 5 }
aks_user_node_pool   = { vm_size = "Standard_D4s_v5", min_count = 3, max_count = 10 }

aks_admin_group_object_ids   = ["00000000-0000-0000-0000-000000000000"]
aks_reader_group_object_ids  = []
aks_api_authorized_ip_ranges = ["203.0.113.0/24"] # replace with office/VPN egress CIDR

appgw_sku          = "WAF_v2"
appgw_waf_mode     = "Prevention"
appgw_min_capacity = 2
appgw_max_capacity = 10

# Private Key Vault. Terraform must then run from a self-hosted agent inside
# (or peered to) the VNet, or from an IP in kv_allowed_ip_ranges.
kv_purge_protection_enabled      = true
kv_soft_delete_retention_days    = 90
kv_public_network_access_enabled = true
kv_network_default_action        = "Deny"
kv_allowed_ip_ranges             = ["203.0.113.0/24"]
kv_enable_private_endpoint       = true

postgres_sku_name              = "GP_Standard_D2ds_v5"
postgres_high_availability     = true
postgres_backup_retention_days = 35
postgres_geo_redundant_backup  = true

log_retention_days = 90
alert_emails       = ["oncall@example.com"]

tags = { owner = "platform-team", cost_center = "crafthinge", criticality = "high" }
