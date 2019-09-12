resource "azurerm_postgresql_server" "default" {
  name                = var.environment_name
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name

  sku {
    name     = var.sql_sku_name
    capacity = var.sql_capacity
    tier     = "GeneralPurpose"
    family   = "Gen5"
  }

  storage_profile {
    storage_mb            = var.sql_storage_in_mb
    backup_retention_days = 35
    geo_redundant_backup  = "Enabled"
  }

  administrator_login          = var.sql_master_username
  administrator_login_password = var.sql_master_password

  version                      = var.sql_version
  ssl_enforcement              = "Disabled"
}
