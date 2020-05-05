variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.16"
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

variable "cluster_private_access" {
  default = false
}

variable "cluster_public_access" {
  default = true
}

variable "cluster_public_access_cidrs" {
  default = ["0.0.0.0/0"]
}


variable "bastion_enabled" {
  default = false
}

variable cidr_block {
  default = "10.2.0.0/16"
}

variable "enable_ipv6" {
  default = false
}

variable "enable_nat" {
  default = true
}

variable "enable_egress_only_internet_gateway" {
  default = false
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

variable "nodes_in_public_subnet" {
  default     = false
  description = "INSECURE! Only use this if you want to avoid paying for the NAT. Also set enable_nat to false"
}

variable "nodes_green_instance_type" {
  default = "t3.micro"
}

variable "nodes_green_root_device_size" {
  default = "20"
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

variable "nodes_green_max_instance_lifetime" {
  default = 604800 // Default to 7 days
}

variable "nodes_blue_instance_type" {
  default = "t3.micro"
}

variable "nodes_blue_root_device_size" {
  default = "20"
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

variable "nodes_blue_max_instance_lifetime" {
  default = 604800 // Default to 7 days
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

variable "foxpass_install" {
  default     = ""
  description = "Make this a string to be read in the user-data"
}

variable "foxpass_base_dn" {
  default = ""
}

variable "foxpass_bind_user" {
  default = ""
}

variable "foxpass_bind_pw" {
  default = ""
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
