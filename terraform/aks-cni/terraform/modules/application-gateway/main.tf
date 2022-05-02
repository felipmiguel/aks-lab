terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "public_ip" {
  name          = var.application_name
  resource_type = "azurerm_public_ip"
  suffixes      = [var.environment, "apgw"]
}

resource "azurerm_public_ip" "gateway_public_ip" {
  name                = azurecaf_name.public_ip.result
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Static"
  sku                 = "Standard"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${var.application_name}-beap"
  frontend_port_name             = "${var.application_name}-feport"
  frontend_ip_configuration_name = "${var.application_name}-feip"
  http_setting_name              = "${var.application_name}-be-htst"
  listener_name                  = "${var.application_name}-httplstn"
  request_routing_rule_name      = "${var.application_name}-rqrt"
  redirect_configuration_name    = "${var.application_name}-rdrcfg"
}

resource "azurecaf_name" "application_gateway" {
  name          = var.application_name
  resource_type = "azurerm_application_gateway"
  suffixes      = [var.environment, "apgw"]
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = azurecaf_name.application_gateway.result
  resource_group_name = var.resource_group
  location            = var.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.gateway_public_ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    # fqdns = [var.backend_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
