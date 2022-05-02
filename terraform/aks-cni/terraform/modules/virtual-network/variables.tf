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

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
}

variable "address_space" {
  type        = string
  description = "VNet address space"
}

variable "private_endpoints_subnet_prefix" {
  type        = string
  description = "Private endpoints subnet prefix"
}

variable "aks_subnet_prefix" {
  type        = string
  description = "Azure Kubernetes Service subnet prefix"
}

variable "app_gateway_subnet_prefix" {
  type        = string
  description = "value of the app gateway subnet prefix"
}
variable "service_endpoints" {
  type        = list(string)
  description = "Service endpoints used by the solution"
}
