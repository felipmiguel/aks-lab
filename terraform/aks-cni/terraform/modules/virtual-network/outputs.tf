output "virtual_network_id" {
  value       = azurerm_virtual_network.virtual_network.id
  description = "Application Virtual Network"
}

output "aks_subnet_id" {
  value       = azurerm_subnet.aks_subnet.id
  description = "Azure Kubernetes Service subnet resource ID"
}

output "private_endpoints_subnet_id" {
  value       = azurerm_subnet.private_endpoints_subnet.id
  description = "Private endpoints dedicated subnet resource ID"
}

output "app_gateway_subnet_id" {
  value       = azurerm_subnet.app_gateway_subnet.id
  description = "Application Gateway subnet resource ID"
}
