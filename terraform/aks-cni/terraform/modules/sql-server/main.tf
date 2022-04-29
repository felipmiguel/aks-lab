terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "mssql_server" {
  name          = var.application_name
  resource_type = "azurerm_mssql_server"
  suffixes      = [var.environment]
}

resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "_%@"
}

resource "azurerm_mssql_server" "database" {
  name                = azurecaf_name.mssql_server.result
  resource_group_name = var.resource_group
  location            = var.location
  version             = "12.0"

  administrator_login          = var.administrator_login
  administrator_login_password = random_password.password.result

  public_network_access_enabled = false

  tags = {
    "environment"      = var.environment
    "application-name" = var.application_name
  }
}

resource "azurecaf_name" "mssql_database" {
  name          = var.application_name
  resource_type = "azurerm_mssql_database"
  suffixes      = [var.environment]
}

resource "azurerm_mssql_database" "database" {
  name      = azurecaf_name.mssql_database.result
  server_id = azurerm_mssql_server.database.id
  collation = "SQL_Latin1_General_CP1_CI_AS"

  sku_name = "GP_Gen5_2"
}

# resource "azurecaf_name" "sql_network_rule" {
#   name          = var.application_name
#   resource_type = "azurerm_network_security_rule"
#   suffixes      = [var.environment]
# }

# # This rule only allows traffic from the apps VNet
# resource "azurerm_mssql_virtual_network_rule" "network_rule" {
#   name      = azurecaf_name.sql_network_rule.result
#   server_id = azurerm_mssql_server.database.id
#   subnet_id = var.subnet_id
# }

resource "azurecaf_name" "private_endpoint" {
  name          = var.application_name
  resource_type = "azurerm_private_endpoint"
  suffixes      = [var.environment, "mssql"]
}


resource "azurerm_private_endpoint" "private_endpoint" {
  name                = azurecaf_name.private_endpoint.result
  location            = var.location
  resource_group_name = var.resource_group
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "${azurerm_mssql_server.database.name}-pe"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mssql_server.database.id
    subresource_names              = ["sqlServer"]
  }
}


# resource "azurerm_private_dns_zone" "mssql_private_dns_zone" {
#   # name = azurecaf_name.azurerm_private_dns_zone.result
#   name                = "privatelink.database.windows.net"
#   resource_group_name = var.resource_group
# }

# resource "azurecaf_name" "dns_network_link" {
#   name          = var.application_name
#   resource_type = "azurerm_private_dns_zone_virtual_network_link"
#   suffixes      = [var.environment, "mssql"]
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "mssql_dns_zone_network_link" {
#   name                  = "privatelink.database.windows.net"
#   resource_group_name   = var.resource_group
#   private_dns_zone_name = azurerm_private_dns_zone.mssql_private_dns_zone.name
#   virtual_network_id    = var.vnet_id
# }

# resource "azurerm_private_dns_a_record" "mssql_dns_a_record" {
#   name                = azurerm_mssql_database.database.name
#   zone_name           = azurerm_private_dns_zone.mssql_private_dns_zone.name
#   resource_group_name = var.resource_group
#   ttl                 = 300
#   records             = azurerm_private_endpoint.private_endpoint.private_service_connection.*.private_ip_address
# }
