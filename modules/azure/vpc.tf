resource "azurerm_route_table" "cluster" {
  name                = var.environment_name
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name

  route {
    name                   = "default"
    address_prefix         = "10.100.0.0/14"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.10.1.1"
  }
}

resource "azurerm_virtual_network" "cluster" {
  name                = var.environment_name
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name
  address_space       = ["${var.cidr}/16"]
}

resource "azurerm_subnet" "cluster" {
  name                 = var.environment_name
  resource_group_name  = azurerm_resource_group.cluster.name
  address_prefixes     = ["${var.cidr}/24"]
  virtual_network_name = azurerm_virtual_network.cluster.name
  service_endpoints    = ["Microsoft.Sql"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet_route_table_association" "cluster" {
  subnet_id      = azurerm_subnet.cluster.id
  route_table_id = azurerm_route_table.cluster.id
}
