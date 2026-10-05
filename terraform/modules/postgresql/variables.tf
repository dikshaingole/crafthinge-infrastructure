variable "name" {
  type        = string
  description = "Globally unique server name"
}
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "tenant_id" { type = string }
variable "vnet_id" { type = string }
variable "delegated_subnet_id" { type = string }
variable "postgres_version" {
  type    = string
  default = "16"
}
variable "sku_name" {
  type    = string
  default = "B_Standard_B1ms"
}
variable "storage_mb" {
  type    = number
  default = 32768
}
variable "zone" {
  type    = string
  default = "1"
}
variable "high_availability_enabled" {
  type    = bool
  default = false
}
variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}
variable "administrator_login" {
  type    = string
  default = "crafthingeadmin"
}
variable "administrator_password" {
  type      = string
  sensitive = true
}
variable "databases" {
  type = list(string)
}
variable "tags" {
  type    = map(string)
  default = {}
}
