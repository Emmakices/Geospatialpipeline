resource "azurerm_container_app" "api" {
  name                         = "ca-geopipe-api-dev"
  resource_group_name          = azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.ca_env.id
  revision_mode                = "Single"

  secret {
    name  = "api-key"
    value = data.azurerm_key_vault_secret.api_key.value
  }


  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api_uami.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.api_uami.id
  }

  template {
    container {
      name   = "api"
      image  = "acrgeopipe2325.azurecr.io/geospatial-api:dev"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "API_KEY"
        secret_name = "api-key"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags = {
    project = "geospatial-pipeline"
    env     = "dev"
  }
}

data "azurerm_key_vault_secret" "api_key" {
  name         = "api-key"
  key_vault_id = azurerm_key_vault.kv.id
}

