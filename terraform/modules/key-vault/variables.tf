variable "name" {
  type        = string
  description = "Globally unique, 3-24 chars"
}
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "purge_protection_enabled" {
  type        = bool
  default     = false
  description = "true in prod. Once enabled it cannot be turned off, and the vault name is blocked for the retention period after deletion."
}
variable "soft_delete_retention_days" {
  type    = number
  default = 7
}
variable "public_network_access_enabled" {
  type    = bool
  default = true
}
variable "network_default_action" {
  type        = string
  default     = "Allow"
  description = "Deny in prod (reach it via private endpoint / self-hosted agents)"
}
variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}
variable "secrets_officer_principal_ids" {
  type        = list(string)
  default     = []
  description = "Can create/update secrets (Terraform pipeline, platform admins)"
}
variable "secrets_user_principal_ids" {
  type        = map(string)
  default     = {}
  description = "Read-only secret access, keyed by a stable name (e.g. appgw = <principal id>)"
}
variable "enable_private_endpoint" {
  type    = bool
  default = false
}
variable "vnet_id" {
  type    = string
  default = null
}
variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}
variable "tags" {
  type    = map(string)
  default = {}
}
