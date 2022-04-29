terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "acr" {
  name          = var.application_name
  resource_type = "azurerm_container_registry"
  suffixes      = [var.environment]
}

resource "azurerm_container_registry" "acr" {
  name                = azurecaf_name.acr.result
  resource_group_name = var.resource_group
  location            = var.location
  admin_enabled       = false
  sku                 = "Premium"
  public_network_access_enabled = false
    
}

resource "azurecaf_name" "private_endpoint" {
  name          = var.application_name
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment, "acr"]
}


resource "azurerm_private_endpoint" "private_endpoint" {
  name                = azurecaf_name.private_endpoint.result
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_container_registry.acr.name}-pe"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
  }
}