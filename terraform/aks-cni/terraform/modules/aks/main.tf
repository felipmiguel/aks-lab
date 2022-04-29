terraform {
  required_providers {
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.16"
    }
  }
}

resource "azurecaf_name" "aks_cluster" {
  name          = var.application_name
  resource_type = "azurerm_kubernetes_cluster"
  suffixes      = [var.environment]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = azurecaf_name.aks_cluster.result
  resource_group_name = var.resource_group
  location            = var.location
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name           = "defaultpool"
    node_count     = 2
    vm_size        = "Standard_B2s"
    vnet_subnet_id = var.aks_subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}

# grant permission to aks to pull images from acr
resource "azurerm_role_assignment" "acrpull_role" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

data "azurerm_public_ip" "aks_public_ip" {
  name                = reverse(split("/", tolist(azurerm_kubernetes_cluster.aks.network_profile.0.load_balancer_profile.0.effective_outbound_ips)[0]))[0]
  resource_group_name = azurerm_kubernetes_cluster.aks.resource_group_name
}
