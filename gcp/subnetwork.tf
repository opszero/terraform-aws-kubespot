resource "google_compute_subnetwork" "subnet" {
  name    = var.cluster_name
  region  = var.region
  network = google_compute_network.network.self_link

  enable_flow_logs = true
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_network" "network" {
  name                    = var.cluster_name
  auto_create_subnetworks = false
}
