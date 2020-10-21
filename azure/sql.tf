resource "azurerm_postgresql_server" "default" {
  count = var.postgres_sql_enabled ? 1 : 0

  name                = var.environment_name
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name

  sku_name = var.sql_sku_name

  administrator_login          = var.sql_master_username
  administrator_login_password = var.sql_master_password

  version                 = var.postgres_sql_version
  ssl_enforcement_enabled = false
}

resource "azurerm_postgresql_virtual_network_rule" "default" {
  count = var.postgres_sql_enabled ? 1 : 0

  name                                 = var.environment_name
  resource_group_name                  = azurerm_resource_group.cluster.name
  server_name                          = azurerm_postgresql_server.default.name
  subnet_id                            = azurerm_subnet.cluster.id
  ignore_missing_vnet_service_endpoint = true
}

resource "azurerm_postgresql_database" "qa" {
  count = var.postgres_sql_enabled ? 1 : 0

  name                = "qa"
  resource_group_name = azurerm_resource_group.cluster.name
  server_name         = azurerm_postgresql_server.default.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
