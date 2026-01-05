output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "raw_container_name" {
  value = azurerm_storage_container.raw.name
}
