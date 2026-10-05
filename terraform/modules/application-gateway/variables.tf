variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "subnet_id" { type = string }
variable "sku_name" {
  type    = string
  default = "Standard_v2"
  validation {
    condition     = contains(["Standard_v2", "WAF_v2"], var.sku_name)
    error_message = "Use Standard_v2 or WAF_v2."
  }
}
variable "waf_mode" {
  type    = string
  default = "Detection"
}
variable "min_capacity" {
  type    = number
  default = 0
}
variable "max_capacity" {
  type    = number
  default = 2
}
variable "availability_zones" {
  type    = list(string)
  default = null
}
variable "domain_name_label" {
  type        = string
  default     = null
  description = "Optional <label>.<region>.cloudapp.azure.com name for quick testing before real DNS"
}
variable "tags" {
  type    = map(string)
  default = {}
}
