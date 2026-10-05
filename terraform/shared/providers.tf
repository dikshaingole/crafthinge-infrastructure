provider "azurerm" {
  features {}
  storage_use_azuread = true # shared keys are disabled on the state account
}
