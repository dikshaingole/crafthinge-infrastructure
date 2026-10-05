variable "name" {
  type        = string
  description = "Resource group name, e.g. rg-crafthinge-dev"
}
variable "location" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}
