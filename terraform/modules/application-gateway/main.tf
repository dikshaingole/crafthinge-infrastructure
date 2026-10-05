locals {
  frontend_ip_name = "fip-public"
  frontend_port    = "port-80"
  backend_pool     = "pool-default"
  backend_settings = "settings-default"
  listener         = "listener-default"
  routing_rule     = "rule-default"
}

resource "azurerm_public_ip" "this" {
  name                = "pip-appgw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availability_zones
  domain_name_label   = var.domain_name_label
  tags                = var.tags
}

# Identity App Gateway uses to read TLS certificates from Key Vault (Phase 6).
resource "azurerm_user_assigned_identity" "this" {
  name                = "id-appgw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_web_application_firewall_policy" "this" {
  count               = var.sku_name == "WAF_v2" ? 1 : 0
  name                = "waf-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  policy_settings {
    enabled = true
    mode    = var.waf_mode # Detection in dev (tune rules), Prevention in prod
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
  tags = var.tags
}

# The listener/pool/rule below are placeholders: Azure requires at least one
# of each to create the gateway. After that, AGIC owns the routing config and
# rewrites it from Kubernetes Ingress objects - so Terraform ignores it.
resource "azurerm_application_gateway" "this" {
  name                = "agw-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = var.availability_zones
  firewall_policy_id  = var.sku_name == "WAF_v2" ? azurerm_web_application_firewall_policy.this[0].id : null

  sku {
    name = var.sku_name
    tier = var.sku_name
  }

  autoscale_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101" # TLS 1.2+ only
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = var.subnet_id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_name
    public_ip_address_id = azurerm_public_ip.this.id
  }

  frontend_port {
    name = local.frontend_port
    port = 80
  }

  backend_address_pool {
    name = local.backend_pool
  }

  backend_http_settings {
    name                  = local.backend_settings
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = local.listener
    frontend_ip_configuration_name = local.frontend_ip_name
    frontend_port_name             = local.frontend_port
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.routing_rule
    rule_type                  = "Basic"
    http_listener_name         = local.listener
    backend_address_pool_name  = local.backend_pool
    backend_http_settings_name = local.backend_settings
    priority                   = 100
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags,
      backend_address_pool,
      backend_http_settings,
      frontend_port,
      http_listener,
      probe,
      redirect_configuration,
      request_routing_rule,
      rewrite_rule_set,
      ssl_certificate,
      url_path_map,
    ]
  }
}
