# BOOTSTRAP (chicken-and-egg): this stack CREATES the state storage account,
# so the very first apply must use local state.
#
#   1. Leave this block commented.  terraform init && terraform apply -var-file=shared.tfvars
#   2. Put the output storage account name into backend.hcl
#   3. Uncomment the block below and run:
#        terraform init -migrate-state -backend-config=backend.hcl
#   4. Delete the local terraform.tfstate* files. From now on it runs in the pipeline.
#
# terraform {
#   backend "azurerm" {
#     use_azuread_auth = true
#   }
# }
