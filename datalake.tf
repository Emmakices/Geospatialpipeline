resource "azurerm_storage_account" "lake" {
  name                     = "geopipe2325dl" # must be globally unique, lowercase, 3-24 chars
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # ADLS Gen2
  is_hns_enabled = true

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  tags = {
    env     = "dev"
    project = "geospatial-pipeline"
  }
}

resource "azurerm_storage_container" "lake_raw" {
  name                  = "raw-osm"
  storage_account_id    = azurerm_storage_account.lake.id
  container_access_type = "private"
}

# Let Databricks Access Connector read from the lake
resource "azurerm_role_assignment" "ac_lake_blob_reader" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_databricks_access_connector.ac.identity[0].principal_id
}

output "lake_storage_account_name" {
  value = azurerm_storage_account.lake.name
}
