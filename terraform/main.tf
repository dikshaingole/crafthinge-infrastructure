data "azurerm_client_config" "current" {}

# The shared registry created by terraform/shared
data "azurerm_container_registry" "shared" {
  name                = var.shared_acr_name
  resource_group_name = var.shared_resource_group_name
}

# Short random suffix for names that must be globally unique.
resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

# ---------------------------------------------------------------- foundation
module "resource_group" {
  source   = "./modules/resource-group"
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}

module "networking" {
  source              = "./modules/networking"
  name                = local.name
  location            = var.location
  resource_group_name = module.resource_group.name
  address_space       = var.vnet_address_space
  subnet_prefixes     = var.subnet_prefixes
  tags                = local.tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  name                = local.name
  location            = var.location
  resource_group_name = module.resource_group.name
  retention_in_days   = var.log_retention_days
  daily_quota_gb      = var.log_daily_quota_gb
  alert_emails        = var.alert_emails
  tags                = local.tags
}

# ---------------------------------------------------------------- edge
module "application_gateway" {
  source              = "./modules/application-gateway"
  name                = local.name
  location            = var.location
  resource_group_name = module.resource_group.name
  subnet_id           = module.networking.appgw_subnet_id
  sku_name            = var.appgw_sku
  waf_mode            = var.appgw_waf_mode
  min_capacity        = var.appgw_min_capacity
  max_capacity        = var.appgw_max_capacity
  availability_zones  = var.availability_zones
  domain_name_label   = "${local.name}-${random_string.suffix.result}"
  tags                = local.tags
}

# ---------------------------------------------------------------- compute
module "aks" {
  source                          = "./modules/aks"
  name                            = local.name
  location                        = var.location
  resource_group_name             = module.resource_group.name
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  kubernetes_version              = var.kubernetes_version
  sku_tier                        = var.aks_sku_tier
  subnet_id                       = module.networking.aks_subnet_id
  availability_zones              = var.availability_zones
  system_node_pool                = var.aks_system_node_pool
  user_node_pool                  = var.aks_user_node_pool
  admin_group_object_ids          = var.aks_admin_group_object_ids
  api_server_authorized_ip_ranges = var.aks_api_authorized_ip_ranges
  application_gateway_id          = module.application_gateway.id
  log_analytics_workspace_id      = module.monitoring.log_analytics_workspace_id
  tags                            = local.tags
}

# ---------------------------------------------------------------- secrets
module "key_vault" {
  source                        = "./modules/key-vault"
  name                          = "kv-${local.name}-${random_string.suffix.result}"
  location                      = var.location
  resource_group_name           = module.resource_group.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  purge_protection_enabled      = var.kv_purge_protection_enabled
  soft_delete_retention_days    = var.kv_soft_delete_retention_days
  public_network_access_enabled = var.kv_public_network_access_enabled
  network_default_action        = var.kv_network_default_action
  allowed_ip_ranges             = var.kv_allowed_ip_ranges
  enable_private_endpoint       = var.kv_enable_private_endpoint
  vnet_id                       = module.networking.vnet_id
  private_endpoint_subnet_id    = module.networking.private_endpoints_subnet_id

  # Whoever runs Terraform (pipeline SP) can write secrets.
  secrets_officer_principal_ids = [data.azurerm_client_config.current.object_id]

  # App Gateway reads its TLS certificate from Key Vault (Phase 6).
  secrets_user_principal_ids = {
    appgw = module.application_gateway.identity_principal_id
  }
  tags = local.tags
}

# RBAC role assignments take a little while to propagate; without this pause
# the first secret write can fail with 403.
resource "time_sleep" "kv_rbac_propagation" {
  create_duration = "60s"
  depends_on      = [module.key_vault]
}

# ---------------------------------------------------------------- data
resource "random_password" "postgres_admin" {
  length           = 32
  special          = true
  override_special = "!#%*-_=+"
}

module "postgresql" {
  source                       = "./modules/postgresql"
  name                         = "psql-${local.name}-${random_string.suffix.result}"
  location                     = var.location
  resource_group_name          = module.resource_group.name
  tenant_id                    = data.azurerm_client_config.current.tenant_id
  vnet_id                      = module.networking.vnet_id
  delegated_subnet_id          = module.networking.postgres_subnet_id
  sku_name                     = var.postgres_sku_name
  storage_mb                   = var.postgres_storage_mb
  high_availability_enabled    = var.postgres_high_availability
  backup_retention_days        = var.postgres_backup_retention_days
  geo_redundant_backup_enabled = var.postgres_geo_redundant_backup
  administrator_password       = random_password.postgres_admin.result
  databases                    = local.databases
  tags                         = local.tags
}

module "service_bus" {
  source              = "./modules/service-bus"
  name                = "sb-${local.name}-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = module.resource_group.name
  sku                 = "Standard"
  topics = {
    "order-events" = ["notification-service", "delivery-service"]
  }
  tags = local.tags
}

# ---------------------------------------------------------------- secrets written by Terraform
# NOTE: these values are also stored in Terraform state -> the state account
# is locked down accordingly (see docs/terraform-state.md).
resource "azurerm_key_vault_secret" "postgres_admin_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres_admin.result
  key_vault_id = module.key_vault.id
  content_type = "password"
  depends_on   = [time_sleep.kv_rbac_propagation]
}

resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "appinsights-connection-string"
  value        = module.monitoring.app_insights_connection_string
  key_vault_id = module.key_vault.id
  depends_on   = [time_sleep.kv_rbac_propagation]
}
