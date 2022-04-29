terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.4.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
}

data "http" "myip" {
  url = "http://whatismyip.akamai.com"
}

locals {
  myip = chomp(data.http.myip.body)
}

resource "azurecaf_name" "resource_group" {
  name          = var.application_name
  resource_type = "azurerm_resource_group"
  suffixes      = [local.environment]
}

resource "azurerm_resource_group" "main" {
  name     = azurecaf_name.resource_group.result
  location = var.location

  tags = {
    "terraform"        = "true"
    "environment"      = local.environment
    "application-name" = var.application_name
    "nubesgen-version" = "test"
  }
}

module "application" {
  source                         = "./modules/aks"
  resource_group                 = azurerm_resource_group.main.name
  application_name               = var.application_name
  environment                    = local.environment
  location                       = var.location
  dns_prefix                     = var.dns_prefix
  aks_subnet_id                  = module.network.aks_subnet_id
  acr_id                         = module.acr.acr_id
  aks_rbac_admin_group_object_id = module.admins.admin_group_id
}

module "database" {
  source           = "./modules/sql-server"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  subnet_id        = module.network.private_endpoints_subnet_id
  vnet_id          = module.network.virtual_network_id
}

module "application-insights" {
  source           = "./modules/application-insights"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
}

module "key-vault" {
  source           = "./modules/key-vault"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  database_username = module.database.database_username
  database_password = module.database.database_password

  subnet_id = module.network.private_endpoints_subnet_id
  myip      = local.myip
}

module "network" {
  source           = "./modules/virtual-network"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location

  service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault", "Microsoft.ContainerRegistry"]

  address_space                   = var.address_space
  aks_subnet_prefix               = var.aks_subnet_prefix
  private_endpoints_subnet_prefix = var.private_endpoints_subnet_prefix
}

module "acr" {
  source           = "./modules/acr"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  subnet_id        = module.network.private_endpoints_subnet_id
}


module "admins" {
  source           = "./modules/admins"
  application_name = var.application_name
  environment      = local.environment
  admin_ids        = var.admin_ids
}

module "database_dns" {
  source             = "./modules/private-dns"
  resource_group     = azurerm_resource_group.main.name
  environment        = local.environment
  application_name   = var.application_name
  root_dns           = "database.windows.net"
  virtual_network_id = module.network.virtual_network_id
  service_suffix     = "mssql"
  dns_entries = [
    {
      name         = module.database.database_name
      ip_addresses = module.database.server_ip_addresses
    }
  ]
}

module "keyvault_dns" {
  source             = "./modules/private-dns"
  resource_group     = azurerm_resource_group.main.name
  environment        = local.environment
  application_name   = var.application_name
  root_dns           = "vault.azure.net"
  virtual_network_id = module.network.virtual_network_id
  service_suffix     = "kv"
  dns_entries = [
    {
      name         = module.key-vault.vault_name
      ip_addresses = module.key-vault.server_ip_addresses
    }
  ]
}


module "acr_dns" {
  source             = "./modules/private-dns"
  resource_group     = azurerm_resource_group.main.name
  environment        = local.environment
  application_name   = var.application_name
  root_dns           = "azurecr.io"
  virtual_network_id = module.network.virtual_network_id
  service_suffix     = "acr"
  dns_entries = [
    {
      name         = module.acr.registry_name
      ip_addresses = module.acr.server_ip_addresses
    }
  ]
}

module "jumpbox" {
  source           = "./modules/vm"
  resource_group   = azurerm_resource_group.main.name
  application_name = var.application_name
  environment      = local.environment
  location         = var.location
  subnet_id        = module.network.private_endpoints_subnet_id
}
