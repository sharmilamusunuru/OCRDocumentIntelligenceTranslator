variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-dulux-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "translator_location" {
  description = "Azure region for Translator service (must be global)"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase alphanumeric characters)"
  type        = string
  default     = "stduluxdemo"
}

variable "document_intelligence_name" {
  description = "Name of the Document Intelligence service"
  type        = string
  default     = "di-dulux-demo"
}

variable "translator_name" {
  description = "Name of the Translator service"
  type        = string
  default     = "tr-dulux-demo"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "demo"
}
