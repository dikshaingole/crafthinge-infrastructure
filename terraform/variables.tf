# ------------------------------------------------------------------ general
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment must be dev, qa or prod."
  }
}
variable "location" {
  type    = string
  default = "eastus2"
}
variable "availability_zones" {
  type        = list(string)
  default     = null
  description = "e.g. [\"1\",\"2\",\"3\"] in prod. null = no zone pinning (cheaper dev)."
}
variable "tags" {
  type    = map(string)
  default = {}
}

# ------------------------------------------------------------------ shared
variable "shared_acr_name" {
  type    = string
  default = "crafthingeacr"
}
variable "shared_resource_group_name" {
  type    = string
  default = "rg-crafthinge-shared"
}

# ------------------------------------------------------------------ network
variable "vnet_address_space" {
  type = list(string)
}
variable "subnet_prefixes" {
  type = object({
    aks               = string
    appgw             = string
    private_endpoints = string
    postgres          = string
  })
}

# ------------------------------------------------------------------ aks
variable "kubernetes_version" {
  type    = string
  default = null
}
variable "aks_sku_tier" {
  type    = string
  default = "Free"
}
variable "aks_system_node_pool" {
  type = object({
    vm_size   = string
    min_count = number
    max_count = number
  })
}
variable "aks_user_node_pool" {
  type = object({
    vm_size   = string
    min_count = number
    max_count = number
  })
}
variable "aks_admin_group_object_ids" {
  type        = list(string)
  description = "Entra ID group(s) whose members get cluster-admin"
}
variable "aks_reader_group_object_ids" {
  type    = list(string)
  default = []
}
variable "aks_api_authorized_ip_ranges" {
  type        = list(string)
  default     = []
  description = "Restrict the API server to these CIDRs (your office/VPN). Empty = open (dev only)."
}

# ------------------------------------------------------------------ app gateway
variable "appgw_sku" {
  type    = string
  default = "Standard_v2"
}
variable "appgw_waf_mode" {
  type    = string
  default = "Detection"
}
variable "appgw_min_capacity" {
  type    = number
  default = 0
}
variable "appgw_max_capacity" {
  type    = number
  default = 2
}

# ------------------------------------------------------------------ key vault
variable "kv_purge_protection_enabled" {
  type    = bool
  default = false
}
variable "kv_soft_delete_retention_days" {
  type    = number
  default = 7
}
variable "kv_public_network_access_enabled" {
  type    = bool
  default = true
}
variable "kv_network_default_action" {
  type    = string
  default = "Allow"
}
variable "kv_allowed_ip_ranges" {
  type    = list(string)
  default = []
}
variable "kv_enable_private_endpoint" {
  type    = bool
  default = false
}

# ------------------------------------------------------------------ postgres
variable "postgres_sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}
variable "postgres_storage_mb" {
  type    = number
  default = 32768
}
variable "postgres_high_availability" {
  type    = bool
  default = false
}
variable "postgres_backup_retention_days" {
  type    = number
  default = 7
}
variable "postgres_geo_redundant_backup" {
  type    = bool
  default = false
}

# ------------------------------------------------------------------ monitoring
variable "log_retention_days" {
  type    = number
  default = 30
}
variable "log_daily_quota_gb" {
  type    = number
  default = -1
}
variable "alert_emails" {
  type    = list(string)
  default = []
}
