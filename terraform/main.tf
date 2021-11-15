terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.75"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.6"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  // If an environment is set up (dev, test, prod...), it is used in the application name
  environment = var.environment == "" ? "dev" : var.environment
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
  }
}

resource "azurecaf_name" "vnet" {
  name          = var.application_name
  resource_type = "azurerm_virtual_network"
  suffixes      = [local.environment]
}

resource "azurerm_virtual_network" "aks_vnet" {
  name                = azurecaf_name.vnet.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["192.168.0.0/16"]
}

resource "azurecaf_name" "subnet" {
  name          = var.application_name
  resource_type = "azurerm_subnet"
  suffixes      = [local.environment]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = azurecaf_name.subnet.result
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = ["192.168.1.0/24"]
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
}

resource "azurecaf_name" "acr" {
  name          = var.application_name
  resource_type = "azurerm_container_registry"
  suffixes      = [local.environment]
}

resource "azurerm_container_registry" "acr" {
  name                = azurecaf_name.acr.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  admin_enabled       = false
  sku                 = "Standard"
}

resource "azurecaf_name" "log_analytics" {
  name          = var.application_name
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = [local.environment]
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  # The WorkSpace name has to be unique across the whole of azure, not just the current subscription/tenant.
  name                = azurecaf_name.log_analytics.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_workspace_sku
}

resource "azurerm_log_analytics_solution" "test" {
  solution_name         = "ContainerInsights"
  location              = azurerm_log_analytics_workspace.log_analytics.location
  resource_group_name   = azurerm_resource_group.main.name
  workspace_resource_id = azurerm_log_analytics_workspace.log_analytics.id
  workspace_name        = azurerm_log_analytics_workspace.log_analytics.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurecaf_name" "aks_cluster" {
  name          = var.application_name
  resource_type = "azurerm_kubernetes_cluster"
  suffixes      = [local.environment]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = azurecaf_name.aks_cluster.result
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name           = "defaultpool"
    node_count     = 2
    vm_size        = "Standard_B2s"
    vnet_subnet_id = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "Standard"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id
    }
  }
}

# grant permission to aks to pull images from acr
resource "azurerm_role_assignment" "acrpull_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  #   skip_service_principal_aad_check = true
}

data "azurerm_public_ip" "aks_public_ip" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
}
