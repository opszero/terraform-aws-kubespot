resource "azurerm_resource_group" "cluster" {
  name     = var.cluster_name
  location = var.region
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster_name
  location            = "${azurerm_resource_group.cluster.location}"
  resource_group_name = "${azurerm_resource_group.cluster.name}"
  dns_prefix          = "auditkube"

  linux_profile {
    admin_username = "opszero"

    # ssh_key {
    #   key_data = "${file(var.public_ssh_key_path)}"
    # }
  }

  agent_pool_profile {
    name            = "nodesgreen"
    count           = 1
    vm_size         = "Standard_D2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    vnet_subnet_id = "${azurerm_subnet.cluster.id}"
  }

  agent_pool_profile {
    name            = "nodesblue"
    count           = 1
    vm_size         = "Standard_D2_v2"
    os_type         = "Linux"
    os_disk_size_gb = 30

    vnet_subnet_id = "${azurerm_subnet.cluster.id}"
  }

  service_principal {
    client_id     = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin = "azure"
  }

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
