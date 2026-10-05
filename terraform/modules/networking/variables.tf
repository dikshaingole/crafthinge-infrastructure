variable "name" {
  type        = string
  description = "Base name, e.g. crafthinge-dev"
}
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "address_space" {
  type        = list(string)
  description = "e.g. [\"10.0.0.0/16\"]. Use a different /16 per environment so VNets can be peered later."
}
variable "subnet_prefixes" {
  type = object({
    aks               = string
    appgw             = string
    private_endpoints = string
    postgres          = string
  })
}
variable "tags" {
  type    = map(string)
  default = {}
}
