locals {
  name = "crafthinge-${var.environment}"

  tags = merge(var.tags, {
    project     = "crafthinge"
    environment = var.environment
    managed_by  = "terraform"
  })

  # One database per microservice (notification-service keeps no data)
  databases = ["users", "restaurants", "menu", "carts", "orders", "payments", "deliveries"]
}
