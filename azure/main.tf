resource "azurerm_resource_group" "cluster" {
  name     = var.cluster_name
  location = var.region
}

resource "azurerm_kubernetes_cluster" "test" {
  name                = var.cluster_name
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  dns_prefix          = "acctestagent1"

  agent_pool_profile {
    name            = "nodesgreen"
    count           = 1
    vm_size         = "Standard_D1_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  agent_pool_profile {
    name            = "nodesblue"
    count           = 1
    vm_size         = "Standard_D2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30
  }

  # service_principal {
  #   client_id     = "00000000-0000-0000-0000-000000000000"
  #   client_secret = "00000000000000000000000000000000"
  # }

  tags = {
    Environment = var.cluster_name
  }
}

# output "client_certificate" {
#   value = "${azurerm_kubernetes_cluster.test.kube_config.0.client_certificate}"
# }

# output "kube_config" {
#   value = "${azurerm_kubernetes_cluster.test.kube_config_raw}"
# }
