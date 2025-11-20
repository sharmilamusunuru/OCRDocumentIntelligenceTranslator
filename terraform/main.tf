terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    environment = var.environment
    purpose     = "document-intelligence-demo"
  }
}

resource "azurerm_storage_container" "original" {
  name                  = "original"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "translated" {
  name                  = "translated"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "ocrresult" {
  name                  = "ocrresult"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_cognitive_account" "document_intelligence" {
  name                = var.document_intelligence_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  kind                = "FormRecognizer"
  sku_name            = "S0"
  
  tags = {
    environment = var.environment
    purpose     = "document-intelligence-demo"
  }
}

resource "azurerm_cognitive_account" "translator" {
  name                = var.translator_name
  resource_group_name = azurerm_resource_group.main.name
  location            = var.translator_location
  kind                = "TextTranslation"
  sku_name            = "S1"
  
  tags = {
    environment = var.environment
    purpose     = "document-intelligence-demo"
  }
}
