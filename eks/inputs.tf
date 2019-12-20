variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.14"
}

variable "bastion_enabled" {
  default = false
}

variable cidr_block {
  default = "10.2.0.0/16"
}

variable "zones" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "eips" {
  default = []
}

variable "ec2_keypair" {
  default = "opszero"
}

variable "aws_profile" {
  default = "opszero"
}

variable "iam_users" {
  default = []
}

variable "repos" {
  default = []
}

variable "nodes_green_instance_type" {
  default = "t2.micro"
}

variable "nodes_green_desired_capacity" {
  default = 1
}

variable "nodes_green_min_size" {
  default = 1
}

variable "nodes_green_max_size" {
  default = 1
}

variable "nodes_blue_instance_type" {
  default = "t2.micro"
}

variable "nodes_blue_desired_capacity" {
  default = 1
}

variable "nodes_blue_min_size" {
  default = 1
}

variable "nodes_blue_max_size" {
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

variable "logdna_ingestion_key" {
  type    = string
  default = ""
}

variable "redis_enabled" {
  default = false
}

variable "redis_node_type" {
  default = "cache.t2.micro"
}

variable "redis_num_nodes" {
  default = 1
}

variable "sql_enabled" {
  default = false
}

variable "sql_engine" {
  default = "aurora-postgresql"
}

variable "sql_engine_mode" {
  default = "serverless"
}

variable "sql_node_count" {
  default = 0
}

variable "sql_instance_class" {
  default = "db.r4.large"
}

variable "sql_database_name" {
  default = ""
}

variable "sql_master_username" {
  default = ""
}

variable "sql_master_password" {
  default = ""
}

variable "sql_serverless_min" {
  default = 2
}

variable "sql_serverless_max" {
  default = 2
}
