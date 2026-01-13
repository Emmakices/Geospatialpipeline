resource "azurerm_key_vault_access_policy" "databricks_ac" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_databricks_access_connector.ac.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}
