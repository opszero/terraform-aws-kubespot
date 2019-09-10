resource "google_redis_instance" "cache" {
  count = var.redis_enabled ? 1 : 0

  name           = "memory-cache"
  memory_size_gb = 1

  authorized_networks = google_compute_network.network.self_link

  tier = var.redis_ha_enabled ? "STANDARD_HA" : "BASIC"
}