# resource "azurerm_postgresql_server" "test" {
#   name                = "postgresql-server-1"
#   location            = "${azurerm_resource_group.test.location}"
#   resource_group_name = "${azurerm_resource_group.test.name}"

#   sku {
#     name     = "B_Gen5_2"
#     capacity = 2
#     tier     = "Basic"
#     family   = "Gen4"
#   }

#   storage_profile {
#     storage_mb            = 5120
#     backup_retention_days = 7
#     geo_redundant_backup  = "Disabled"
#   }

#   administrator_login          = "psqladminun"
#   administrator_login_password = "H@Sh1CoR3!"
#   version                      = "11"
#   ssl_enforcement              = "Enabled"
# }

# resource "azurerm_postgresql_database" "test" {
#   name                = "exampledb"
#   resource_group_name = "${azurerm_resource_group.test.name}"
#   server_name         = "${azurerm_postgresql_server.test.name}"
#   charset             = "UTF8"
#   collation           = "English_United States.1252"
# }
