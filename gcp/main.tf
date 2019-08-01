resource "google_container_cluster" "cluster" {
  name     = var.cluster_name
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = var.cluster_username
    password = var.cluster_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "nodes_green" {
  name           = "nodes_green"
  location       = var.region
  node_locations = var.zones
  cluster        = google_container_cluster.cluster.name
  node_count     = 1

  node_config {
    machine_type = var.nodes_green_instance_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    autoscaling {
      min_node_count = var.nodes_green_min_size
      max_node_count = var.nodes_green_max_size
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
