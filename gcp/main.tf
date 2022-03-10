data "google_client_config" "current" {}

resource "google_container_cluster" "cluster" {
  name     = var.environment_name
  location = var.region

  network    = google_compute_network.network.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  ip_allocation_policy {}

  min_master_version = var.cluster_version

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = var.cluster_enable_autopilot ? false : true
  initial_node_count       = 1

  enable_autopilot = var.cluster_enable_autopilot

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "nodes" {
  count = var.cluster_enable_autopilot ? 0 : 1

  name       = "nodes"
  location   = var.region
  cluster    = google_container_cluster.cluster.name
  node_count = 1

  autoscaling {
    min_node_count = var.nodes_min_size
    max_node_count = var.nodes_max_size
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.nodes_instance_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}
