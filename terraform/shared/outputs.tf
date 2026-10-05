output "resource_group_name" { value = module.resource_group.name }
output "tfstate_storage_account_name" { value = module.tfstate.name }
output "acr_name" { value = module.acr.name }
output "acr_login_server" { value = module.acr.login_server }
