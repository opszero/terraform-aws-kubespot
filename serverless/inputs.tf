variable "environment_name" {
  type = string
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

variable "repos" {
  default = []
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
