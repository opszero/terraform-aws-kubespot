output "sql_database" {
  value = len(google_sql_database_instance.default) > 0 ? google_sql_database_instance.default[0].name : ""
}

output "private_vpc_network" {
  value = google_compute_network.network.self_link
}
