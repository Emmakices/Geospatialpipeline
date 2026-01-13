resource "azurerm_user_assigned_identity" "api_uami" {
  name                = "uami-geopipe-api-dev"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    project = "geospatial-pipeline"
    env     = "dev"
  }
}

resource "azurerm_role_assignment" "api_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api_uami.principal_id
}
