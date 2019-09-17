resource "google_redis_instance" "cache" {
  count = var.redis_enabled ? 1 : 0

  name           = var.environment_name
  memory_size_gb = var.redis_memory_in_gb

  authorized_network = google_compute_network.network.self_link

  tier = var.redis_ha_enabled ? "STANDARD_HA" : "BASIC"
}
