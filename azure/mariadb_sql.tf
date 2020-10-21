resource "azurerm_mariadb_server" "default" {
  count = var.mariadb_sql_enabled ? 1 : 0

  name                = var.environment_name
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name

  sku_name   = var.sql_sku_name
  storage_mb = 10000

  administrator_login          = var.sql_master_username
  administrator_login_password = var.sql_master_password

  backup_retention_days = 35

  version                       = var.mariadb_sql_version
  ssl_enforcement_enabled       = false
  public_network_access_enabled = false
}

resource "azurerm_mariadb_virtual_network_rule" "default" {
  count = var.mariadb_sql_enabled ? 1 : 0

  name                                 = var.environment_name
  resource_group_name                  = azurerm_resource_group.cluster.name
  server_name                          = azurerm_mariadb_server.default[count.index].name
  subnet_id                            = azurerm_subnet.cluster.id
  ignore_missing_vnet_service_endpoint = true
}

resource "azurerm_mariadb_database" "qa" {
  count = var.mariadb_sql_enabled ? 1 : 0

  name                = "qa"
  resource_group_name = azurerm_resource_group.cluster.name
  server_name         = azurerm_mariadb_server.default[count.index].name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}
