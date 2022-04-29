provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.87.0"
      # version = "~>2.0"
    }
  }
  # terraform version
  required_version = "~>1.1.0"
}
