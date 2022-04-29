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
  suffixes      = [var.environment, "jumpbox"]
}

resource "azurerm_public_ip" "vm_public_ip" {
  name                = azurecaf_name.public_ip.result
  location            = var.location
  resource_group_name = var.resource_group
  allocation_method   = "Dynamic"

  domain_name_label = "fksdlgksldgkh"
}

resource "azurecaf_name" "nic_name" {
  name          = var.application_name
  resource_type = "azurerm_network_interface"
  suffixes      = [var.environment, "jumpbox"]
}

resource "azurerm_network_interface" "vm_nic" {
  name                = azurecaf_name.nic_name.result
  location            = var.location
  resource_group_name = var.resource_group

  ip_configuration {
    name                          = "nic_config"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

resource "azurecaf_name" "vm_name" {
  name          = var.application_name
  resource_type = "azurerm_linux_virtual_machine"
  suffixes      = [var.environment, "jumpbox"]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = azurecaf_name.vm_name.result
  resource_group_name = var.resource_group
  location            = var.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  priority = "Spot"

  eviction_policy = "Deallocate"

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}
