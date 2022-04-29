output "vault_id" {
  value       = azurerm_key_vault.application.id
  description = "The Azure Key Vault ID"
}

# output "vault_uri" {
#   value       = azurerm_key_vault.application.vault_uri
#   description = "The Azure Key Vault URI"
# }

output "vault_name"{
  value = azurerm_key_vault.application.name
  description = "The Azure Key Vault name"
}

output "server_ip_addresses" {
  value = azurerm_private_endpoint.private_endpoint.private_service_connection.*.private_ip_address
  description = "Key Vault private ip addresses"  
}
