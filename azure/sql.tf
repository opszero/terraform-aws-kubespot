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

  version         = var.sql_version
  ssl_enforcement = "Disabled"
}

resource "azurerm_postgresql_virtual_network_rule" "default" {
  name                                 = var.environment_name
  resource_group_name                  = "${azurerm_resource_group.cluster.name}"
  server_name                          = "${azurerm_postgresql_server.default.name}"
  subnet_id                            = "${azurerm_subnet.cluster.id}"
  ignore_missing_vnet_service_endpoint = true
}

resource "azurerm_postgresql_database" "qa" {
  name                = "qa"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  server_name         = "${azurerm_postgresql_server.cluster.name}"
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
