resource "azurerm_resource_group" "cluster" {
  name     = var.environment_name
  location = var.region
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = var.environment_name
  location            = azurerm_resource_group.cluster.location
  resource_group_name = azurerm_resource_group.cluster.name
  dns_prefix          = "auditkube"

  default_node_pool {
    name            = "nodes"
    node_count      = var.nodes_desired_capacity
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30

    vnet_subnet_id = azurerm_subnet.cluster.id
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin = "azure"
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    Environment = var.environment_name
  }
}
