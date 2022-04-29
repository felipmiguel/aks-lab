output "database_name" {
  value       = azurerm_mssql_server.database.name
  description = "The database name."
}
output "database_url" {
  value       = "${azurerm_mssql_server.database.name}.privatelink.database.windows.net:1433;database=${azurerm_mssql_database.database.name};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;"
  description = "The Azure SQL server URL."
}

output "database_username" {
  value       = "${var.administrator_login}@${azurerm_mssql_server.database.name}"
  description = "The Azure SQL server user name."
}

output "database_password" {
  value       = random_password.password.result
  sensitive   = true
  description = "The Azure SQL server password."
}

output "server_ip_addresses"{
  value = azurerm_private_endpoint.private_endpoint.private_service_connection.*.private_ip_address
  description = "values of private ip addresses associated to the private link for the server"
}
