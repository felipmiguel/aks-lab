variable "application_name" {
  type        = string
  description = "The name of your application"
  default     = "fmiguel-akslab"
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

variable "dns_prefix" {
  type    = string
  default = "fmiguel-aks-lab"
}

variable "log_analytics_workspace_sku" {
  type    = string
  default = "PerGB2018"
}
