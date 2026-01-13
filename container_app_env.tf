resource "azurerm_log_analytics_workspace" "law_ca" {
  name                = "law-geopipe-ca-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    project = "geospatial-pipeline"
    env     = "dev"
  }
}

resource "azurerm_container_app_environment" "ca_env" {
  name                       = "cae-geopipe-dev"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law_ca.id

  tags = {
    project = "geospatial-pipeline"
    env     = "dev"
  }
}
