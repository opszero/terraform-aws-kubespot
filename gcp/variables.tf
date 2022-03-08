variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.15"
}

variable "cluster_username" {
}

variable "cluster_password" {
}

variable "region" {
  default = "us-central1"
}

variable "nodes_instance_type" {
  default = "n1-standard-1"
}

variable "nodes_desired_capacity" {
  default = 1
}

variable "nodes_min_size" {
  default = 1
}

variable "nodes_max_size" {
  default = 1
}

//the following below are required for setting up the vpn
variable "foxpass_api_key" {
  type    = string
  default = ""
}

variable "foxpass_vpn_psk" {
  type        = string
  description = "use this for psk generation https://cloud.google.com/vpn/docs/how-to/generating-pre-shared-key"
  default     = ""
}

variable "redis_enabled" {
  default = false
}

variable "redis_memory_in_gb" {
  default = 1
}

variable "redis_ha_enabled" {
  default = false
}

variable "sql_enabled" {
  default = false
}

variable "sql_engine" {
  default = "POSTGRES_11"
}

variable "sql_instance_class" {
  default = "db-f1-micro"
}

variable "sql_master_username" {
  default = ""
}

variable "sql_master_password" {
  default = ""
}
