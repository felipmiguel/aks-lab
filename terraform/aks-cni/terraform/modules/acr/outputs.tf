output "acr_id" {
  value       = azurerm_container_registry.acr.id
  description = "Container registry resource ID"
}

output "registry_name" {
  value       = azurerm_container_registry.acr.name
  description = "Azure Container Registry name"
}

output "server_ip_addresses" {
  value       = azurerm_private_endpoint.private_endpoint.private_service_connection.*.private_ip_address
  description = "Azure Container Registry private ip addresses"
}
