# Control-plane identity. A user-assigned identity (instead of system-assigned)
# lets us grant it Network Contributor on the subnet BEFORE the cluster exists.
resource "azurerm_user_assigned_identity" "control_plane" {
  name                = "id-aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "control_plane_network" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.control_plane.principal_id
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "aks-${var.name}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier # Free for dev, Standard (uptime SLA) for prod

  # --- Identity & access --------------------------------------------------
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.control_plane.id]
  }

  # Workload Identity: pods get Entra tokens (Key Vault, Service Bus, Postgres)
  # without any stored credentials. Used in Phase 6.
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  # Humans authenticate with Entra ID; authorisation is Azure RBAC.
  # No static admin kubeconfig exists.
  local_account_disabled = true
  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  # Azure DevOps never talks to the API server (Argo CD deploys from inside
  # the cluster), so we can restrict it to admin IP ranges.
  dynamic "api_server_access_profile" {
    for_each = length(var.api_server_authorized_ip_ranges) > 0 ? [1] : []
    content {
      authorized_ip_ranges = var.api_server_authorized_ip_ranges
    }
  }

  # --- System node pool: only critical add-ons (CoreDNS, metrics-server...) --
  default_node_pool {
    name                         = "system"
    vm_size                      = var.system_node_pool.vm_size
    os_sku                       = "AzureLinux"
    vnet_subnet_id               = var.subnet_id
    zones                        = var.availability_zones
    auto_scaling_enabled         = true
    min_count                    = var.system_node_pool.min_count
    max_count                    = var.system_node_pool.max_count
    max_pods                     = 30
    only_critical_addons_enabled = true # taint: CriticalAddonsOnly=true:NoSchedule
    temporary_name_for_rotation  = "systemtmp"

    upgrade_settings {
      max_surge = "33%"
    }
  }

  # --- Networking ---------------------------------------------------------
  # Azure CNI (pods get VNet IPs) + Calico network policies.
  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
    outbound_type     = "loadBalancer"
  }

  # --- Add-ons ------------------------------------------------------------
  # AGIC: App Gateway becomes the Kubernetes ingress controller.
  ingress_application_gateway {
    gateway_id = var.application_gateway_id
  }

  # Container Insights -> Log Analytics (managed identity auth, no keys).
  oms_agent {
    log_analytics_workspace_id      = var.log_analytics_workspace_id
    msi_auth_for_monitoring_enabled = true
  }

  # Secrets Store CSI driver + Azure Key Vault provider (Phase 6).
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  azure_policy_enabled = true # Pod security guardrails (non-root etc.)

  # --- Upgrades -----------------------------------------------------------
  automatic_upgrade_channel = "patch"
  node_os_upgrade_channel   = "NodeImage"

  tags = var.tags

  depends_on = [azurerm_role_assignment.control_plane_network]

  lifecycle {
    ignore_changes = [default_node_pool[0].node_count]
  }
}

# User node pool: where the CraftHinge microservices and Argo CD run.
resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "apps"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  mode                  = "User"
  vm_size               = var.user_node_pool.vm_size
  os_sku                = "AzureLinux"
  vnet_subnet_id        = var.subnet_id
  zones                 = var.availability_zones
  auto_scaling_enabled  = true
  min_count             = var.user_node_pool.min_count
  max_count             = var.user_node_pool.max_count
  max_pods              = 50
  node_labels = {
    "workload" = "apps"
  }

  upgrade_settings {
    max_surge = "33%"
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [node_count]
  }
}
