variable "name" {}
variable "location" {}
variable "public_ip" {}

locals {
  ip_whitelist = [var.public_ip]
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.name}-cosmos-db-rg"
  location = var.location
}

resource "random_integer" "ri" {
  min = 100
  max = 999
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.name}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = [
    "10.20.2.0/24"
  ]

  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet#service_endpoints
  service_endpoints = [
    "Microsoft.AzureCosmosDB"
  ]
}

# - Allow access from Azure Portal (without it Data Explorer won't work):
# https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-the-azure-portal
# - Accept connections from within public Azure datacenters:
# https://docs.microsoft.com/en-us/azure/cosmos-db/how-to-configure-firewall#allow-requests-from-global-azure-datacenters-or-other-sources-within-azure
locals {
  # dummy value
  cosmosdb_ip_range_azure = [
    "127.0.0.1",
  ]
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "${var.name}-cosmos-db-${random_integer.ri.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  offer_type = "Standard"
  # for free: first 1000 RU/s and 25 GB storage
  enable_free_tier = true

  kind                 = "MongoDB"
  mongo_server_version = "4.0"

  enable_automatic_failover = true

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  public_network_access_enabled     = true
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = azurerm_subnet.subnet.id
  }

  ip_range_filter = join(",", concat(local.cosmosdb_ip_range_azure, local.ip_whitelist))

  backup {
    type               = "Periodic"
    storage_redundancy = "Local"
    # https://docs.microsoft.com/en-us/azure/cosmos-db/configure-periodic-backup-restore#configure-backup-interval-retention
    interval_in_minutes = 140
    retention_in_hours  = 24
  }

  capabilities {
    name = "EnableServerless"
  }

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
    zone_redundant    = false
  }
}
