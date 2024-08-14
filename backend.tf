terraform {
  backend "azurerm" {
    resource_group_name  = "tfstaten01579648RG"
    storage_account_name = "tfstaten01579648sa"
    container_name       = "tfstatefiles"
    key                  = "terraform.tfstate"
  }

}

