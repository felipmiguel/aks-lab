terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

locals {
  dns_zone_name = "privatelink.${var.root_dns}"
}
resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = local.dns_zone_name
  resource_group_name = var.resource_group
}

resource "azurecaf_name" "dns_network_link" {
  name          = var.application_name
  resource_type = "azurerm_private_dns_zone_virtual_network_link"
  suffixes      = [var.environment, var.service_suffix]
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_network_link" {
  name                  = local.dns_zone_name
  resource_group_name   = var.resource_group
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = var.virtual_network_id
}

resource "azurerm_private_dns_a_record" "dns_a_record" {
  count               = length(var.dns_entries)
  name                = var.dns_entries[count.index].name
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = var.resource_group
  ttl                 = 300
  records             = var.dns_entries[count.index].ip_addresses
}
