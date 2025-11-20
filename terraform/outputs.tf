output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string for the storage account"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_access_key" {
  description = "Primary access key for the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "document_intelligence_endpoint" {
  description = "Endpoint for Document Intelligence service"
  value       = azurerm_cognitive_account.document_intelligence.endpoint
}

output "document_intelligence_key" {
  description = "API key for Document Intelligence service"
  value       = azurerm_cognitive_account.document_intelligence.primary_access_key
  sensitive   = true
}

output "translator_endpoint" {
  description = "Endpoint for Translator service"
  value       = azurerm_cognitive_account.translator.endpoint
}

output "translator_key" {
  description = "API key for Translator service"
  value       = azurerm_cognitive_account.translator.primary_access_key
  sensitive   = true
}

output "translator_location" {
  description = "Location of Translator service"
  value       = azurerm_cognitive_account.translator.location
}

output "original_container_name" {
  description = "Name of the original files container"
  value       = azurerm_storage_container.original.name
}

output "translated_container_name" {
  description = "Name of the translated files container"
  value       = azurerm_storage_container.translated.name
}

output "ocrresult_container_name" {
  description = "Name of the OCR results container"
  value       = azurerm_storage_container.ocrresult.name
}
