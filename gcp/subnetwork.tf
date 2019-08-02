resource "google_compute_subnetwork" "subnet" {
  name   = var.cluster_name
  region = var.region

  network = google_compute_network.network.self_link

  # TODO: Convert to variable
  ip_cidr_range = "10.2.0.0/16"

  enable_flow_logs = true

  # TODO: Enable this.
  #   log_config {
  #     aggregation_interval = "INTERVAL_10_MIN"
  #     flow_sampling        = 0.5
  #     metadata             = "INCLUDE_ALL_METADATA"
  #  }

  depends_on = ["google_compute_network.network"]
}

resource "google_compute_network" "network" {
  name                    = var.cluster_name
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.network.self_link
}
