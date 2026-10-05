variable "location" {
  type    = string
  default = "eastus2"
}
variable "acr_name" {
  type        = string
  default     = "crafthingeacr"
  description = "Must be globally unique. If taken, add a suffix, e.g. crafthingeacr01"
}
variable "acr_sku" {
  type    = string
  default = "Standard"
}
variable "terraform_pipeline_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object IDs of the Terraform pipeline service connections (dev/qa/prod)"
}
variable "ci_pipeline_principal_ids" {
  type        = list(string)
  default     = []
  description = "Object ID of the application CI service connection (gets AcrPush)"
}
variable "tags" {
  type    = map(string)
  default = {}
}
