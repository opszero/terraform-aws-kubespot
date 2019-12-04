output "sql_database" {
  value = google_sql_database_instance.default[0].name
}