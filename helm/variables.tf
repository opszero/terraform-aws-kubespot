variable "nginx_replica_count" {
  default = 1
}

variable "datadog_api_key" {}
variable "datadog_values" {
  default = "${file("${path.module}/datadog.yml")}"
}
