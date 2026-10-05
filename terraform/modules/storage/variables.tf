variable "name" {
  type        = string
  description = "Globally unique, 3-24 lowercase letters/digits"
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "replication_type" {
  type        = string
  default     = "GRS"
  description = "GRS keeps a copy of state in the paired region"
}
variable "containers" {
  type    = list(string)
  default = ["tfstate"]
}
variable "soft_delete_retention_days" {
  type    = number
  default = 30
}
variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Microsoft-hosted agents need public access. Set false when using self-hosted agents in the VNet."
}
variable "blob_data_contributor_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs (pipeline service principals, admins) that may read/write state"
}
variable "enable_delete_lock" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}
