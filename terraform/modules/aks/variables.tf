variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "kubernetes_version" {
  type        = string
  default     = null
  description = "null = AKS default. Pin it in prod and upgrade deliberately (dev first)."
}
variable "sku_tier" {
  type    = string
  default = "Free"
}
variable "subnet_id" { type = string }
variable "availability_zones" {
  type    = list(string)
  default = null
}
variable "service_cidr" {
  type        = string
  default     = "172.16.0.0/16"
  description = "Kubernetes Service IPs. Must NOT overlap the VNet or anything it peers with."
}
variable "dns_service_ip" {
  type    = string
  default = "172.16.0.10"
}
variable "system_node_pool" {
  type = object({
    vm_size   = string
    min_count = number
    max_count = number
  })
}
variable "user_node_pool" {
  type = object({
    vm_size   = string
    min_count = number
    max_count = number
  })
}
variable "admin_group_object_ids" {
  type        = list(string)
  description = "Entra ID groups that get cluster-admin"
}
variable "api_server_authorized_ip_ranges" {
  type    = list(string)
  default = []
}
variable "application_gateway_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
