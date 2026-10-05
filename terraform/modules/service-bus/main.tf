# Async events: order-service publishes "order-events"; notification-service
# and delivery-service each consume through their own subscription.
# local_auth_enabled = false -> no connection strings; Workload Identity only.
resource "azurerm_servicebus_namespace" "this" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  local_auth_enabled  = false
  minimum_tls_version = "1.2"
  tags                = var.tags
}

resource "azurerm_servicebus_topic" "this" {
  for_each     = var.topics
  name         = each.key
  namespace_id = azurerm_servicebus_namespace.this.id
}

locals {
  subscriptions = merge([
    for topic, subs in var.topics : {
      for s in subs : "${topic}/${s}" => { topic = topic, name = s }
    }
  ]...)
}

resource "azurerm_servicebus_subscription" "this" {
  for_each           = local.subscriptions
  name               = each.value.name
  topic_id           = azurerm_servicebus_topic.this[each.value.topic].id
  max_delivery_count = 10 # then the message goes to the dead-letter queue
}
