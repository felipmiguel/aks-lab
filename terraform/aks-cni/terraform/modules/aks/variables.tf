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

variable "dns_prefix" {
  type        = string
  description = "The DNS prefix for the cluster"
}

variable "aks_subnet_id" {
  type        = string
  description = "The ID of the AKS subnet"
}

variable "acr_id" {
  type = string
  description = "value of the Azure Container Registry resource id"  
}
