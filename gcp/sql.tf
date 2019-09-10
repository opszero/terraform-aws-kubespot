resource "random_id" "server" {
  byte_length = 3
}

resource "google_sql_database_instance" "default" {
  count = var.sql_enabled ? 1 : 0
  name             = "${var.environment_name}-${random_id.server.hex}"
  database_version = var.sql_engine

  settings {
    tier = var.sql_instance_class
    ip_configuration {
      ipv4_enabled    = "true"
      private_network = google_compute_network.network.self_link
    }
  }
}

resource "google_sql_user" "user" {
  name     = var.sql_master_username
  password = var.sql_master_password
  instance = "${google_sql_database_instance.default.name}"
}
