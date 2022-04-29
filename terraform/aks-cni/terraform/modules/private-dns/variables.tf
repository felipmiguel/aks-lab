variable "resource_group" {
  type        = string
  description = "The resource group"
}

variable "application_name" {
  type        = string
  description = "The name of your application"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = "dev"
}

# variable "location" {
#   type        = string
#   description = "The Azure region where all resources in this example should be created"
# }

variable "root_dns" {
  type = string
}

variable "virtual_network_id" {
  type = string
}

variable "dns_entries" {
  type = list(object({
    name : string
    ip_addresses : list(string)
  }))
}

variable "service_suffix" {
    type = string
  
}
