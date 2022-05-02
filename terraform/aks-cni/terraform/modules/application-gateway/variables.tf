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

variable "subnet_id" {
  type        = string
  description = "The subnet to attach the application gateway to be created"
}

# variable "backend_address" {
#     type        = string
#     description = "The backend address to use for the application gateway"  
# }
