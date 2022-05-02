variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = "aks-lab"
}

variable "environment" {
  type        = string
  description = "The environment (dev, test, prod...)"
  default     = ""
}

variable "location" {
  type        = string
  description = "The Azure region where all resources in this example should be created"
  default     = "westeurope"
}

variable "address_space" {
  type        = string
  description = "Virtual Network address space"
  default     = "10.11.0.0/16"
}

variable "aks_subnet_prefix" {
  type        = string
  description = "AKS subnet prefix"
  default     = "10.11.0.0/24"
}

variable "private_endpoints_subnet_prefix" {
  type        = string
  description = "Private endpoints subnet prefix"
  default     = "10.11.1.0/24"
}

variable "app_gateway_subnet_prefix" {
  type        = string
  description = "Application gateway subnet prefix"
  default     = "10.11.2.0/24"
}

variable "dns_prefix" {
  type    = string
  default = "fmiguel-aks-lab"
}

variable "admin_ids" {
  type        = list(string)
  description = "List of Azure Active Directory user object IDs that will be added to a new group and granted admin access to the cluster"
}
