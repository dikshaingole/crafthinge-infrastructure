variable "name" { type = string }
variable "location" { type = string }
variable "resource_group_name" { type = string }
variable "retention_in_days" {
  type    = number
  default = 30
}
variable "daily_quota_gb" {
  type        = number
  default     = -1
  description = "-1 = unlimited. Set e.g. 2 in dev to cap cost."
}
variable "alert_emails" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
