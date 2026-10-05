variable "name" {
  type        = string
  description = "Globally unique, 5-50 alphanumeric characters"
}
variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "sku" {
  type    = string
  default = "Standard"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be Basic, Standard or Premium."
  }
}
variable "zone_redundancy_enabled" {
  type    = bool
  default = false
}
variable "push_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs allowed to push images (the CI pipeline service principal)"
}
variable "tags" {
  type    = map(string)
  default = {}
}
