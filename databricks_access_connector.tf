resource "azurerm_databricks_access_connector" "ac" {
  name                = "ac-geopipe2325"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  identity {
    type = "SystemAssigned"
  }

  tags = {
    env     = "dev"
    project = "geospatial-pipeline"
  }
}

# Grant the connector permission to read blobs from the storage account
resource "azurerm_role_assignment" "ac_blob_reader" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_databricks_access_connector.ac.identity[0].principal_id
}

output "databricks_access_connector_id" {
  value = azurerm_databricks_access_connector.ac.id
}

output "databricks_access_connector_principal_id" {
  value = azurerm_databricks_access_connector.ac.identity[0].principal_id
}
