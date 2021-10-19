variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.15"
}

variable "cluster_logging" {
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "node_groups" {
  default = {
    "t2.micro" = {
      instance_type = "t2.micro",
      node_disk_size = 20,
      node_desired_capacity = 1,
      nodes_max_size = 1,
      nodes_min_size = 1
    },
    "t3.small" = {
      instance_type = "t3.small",
      node_disk_size = 20,
      node_desired_capacity = 1,
      nodes_max_size = 1,
      nodes_min_size = 1
    },
    
  }
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

variable "fargate_enabled" {
  default = false
}
