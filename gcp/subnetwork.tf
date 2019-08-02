resource "google_compute_subnetwork" "subnet" {
  name    = var.cluster_name
  network = google_compute_network.network

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
