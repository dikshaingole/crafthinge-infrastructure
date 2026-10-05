location = "eastus2"
acr_name = "crafthingeacr"
acr_sku  = "Standard"

# Fill these in after creating the Azure DevOps service connections (docs/02-terraform.md)
terraform_pipeline_principal_ids = []
ci_pipeline_principal_ids        = []

tags = {
  owner       = "platform-team"
  cost_center = "crafthinge"
}
