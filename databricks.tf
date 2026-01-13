resource "azurerm_databricks_workspace" "dbw" {
  name                = "dbw-geopipe2325"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku = "standard"

  # Databricks will create a managed resource group for its internal resources
  managed_resource_group_name = "rg-dbw-geopipe2325-managed"

  tags = {
    env     = "dev"
    project = "geospatial-pipeline"
  }
}

output "databricks_workspace_id" {
  value = azurerm_databricks_workspace.dbw.id
}

output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.dbw.workspace_url
}
