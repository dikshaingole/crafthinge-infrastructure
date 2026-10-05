variable "name" {
  type        = string
  description = "Globally unique namespace name"
}
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "sku" {
  type        = string
  default     = "Standard"
  description = "Standard is the minimum tier that supports topics"
}
variable "topics" {
  type        = map(list(string))
  description = "topic name => list of subscription names"
}
variable "tags" {
  type    = map(string)
  default = {}
}
