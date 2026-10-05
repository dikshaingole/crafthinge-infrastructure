# Long-lived resources shared by every environment:
#   - Terraform state storage (one container, one state file per stack)
#   - The container registry (build once, promote the same image everywhere)

data "azurerm_client_config" "current" {}

locals {
  tags = merge(var.tags, {
    project    = "crafthinge"
    stack      = "shared"
    managed_by = "terraform"
  })
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

module "resource_group" {
  source   = "../modules/resource-group"
  name     = "rg-crafthinge-shared"
  location = var.location
  tags     = local.tags
}

module "tfstate" {
  source              = "../modules/storage"
  name                = "sttfcrafthinge${random_string.suffix.result}"
  resource_group_name = module.resource_group.name
  location            = var.location
  replication_type    = "GRS"
  containers          = ["tfstate"]
  blob_data_contributor_principal_ids = distinct(concat(
    [data.azurerm_client_config.current.object_id],
    var.terraform_pipeline_principal_ids
  ))
  tags = local.tags
}

module "acr" {
  source              = "../modules/acr"
  name                = var.acr_name
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = var.acr_sku
  push_principal_ids  = var.ci_pipeline_principal_ids
  tags                = local.tags
}
