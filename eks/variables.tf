variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.20"
}

variable "cluster_autoscaler_enabled" {
  default = true
}


// App version should match the kubernetes version with in the chart
// chart version 9.9.2 support kubernetes version 1.20
// to get the chart version `helm search repo autoscaler/cluster-autoscaler --versions`
variable "cluster_autoscaler_version" {
  default = "9.9.2"
}

variable "cluster_autoscaler_name" {
  default = "cluster-autoscaler"
}

variable "alb_name" {
  default = "aws-load-balancer-controller"
}

variable "aws_load_balancer_controller_enabled" {
  default = true
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

variable "instance_userdata" {
  default = ""
}


variable "bastion_enabled" {
  default = false
}

variable "bastion_eip_enabled" {
  default = false
}

variable "bastion_vpn_allowed_cidrs" {
  description = "These are the IPs that the bastion and VPN allow connections from."
  default     = ["0.0.0.0/0"]
}

variable "cidr_block" {
  description = "The CIDR block used by the VPC"
  default     = "10.2.0.0/16"
}

variable "cidr_block_public_subnet" {
  description = "The CIDR block used by the private subnet"
  default = [
    "10.2.0.0/24",
    "10.2.1.0/24"
  ]
}

variable "cidr_block_private_subnet" {
  description = "The CIDR block used by the private subnet"
  default = [
    "10.2.2.0/24",
    "10.2.3.0/24"
  ]
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

variable "bastion_ec2_keypair" {
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

variable "nodes_green_subnet_ids" {
  default = []
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

variable "ami_image" {
  default = ""
}

variable "nodes_blue_subnet_ids" {
  default = []
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

variable "foxpass_eip_enabled" {
  default = false
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
  default = "cache.t3.micro"
}

variable "redis_engine_version" {
  default = "6.x"
}

variable "sql_cluster_enabled" {
  default = false
}

variable "sql_rds_multi_az" {
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
  default = "db.t3.medium"
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

variable "sql_serverless_seconds_until_auto_pause" {
  default = 300
}

variable "sql_instance_enabled" {
  default = false
}

variable "sql_instance_engine" {
  default = "postgres"
}

variable "sql_engine_version" {
  default = "12.7"
}

variable "sql_encrypted" {
  default = true
}

variable "sql_identifier" {
  description = "The name of the database"
  default     = ""
}

variable "sql_parameter_group_name" {
  default = ""
}

variable "monitoring_role_arn" {
  default = ""
}

variable "enabled_metrics_asg" {
  default = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingCapacity",
    "GroupPendingInstances",
    "GroupStandbyCapacity",
    "GroupStandbyInstances",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances",
  ]
}

variable "vpc_flow_logs_enabled" {
  default = false
}

variable "efs_enabled" {
  default = false
}

variable "sso_roles" {
  default = {
    admin_roles = [
      // "arn:aws:iam::12345:role/AWSReservedSSO_AD-EKS-Admins_b2abd90bad1696ac"
    ]
    readonly_roles = [
      // "arn:aws:iam::12345:role/AWSReservedSSO_AD-EKS-ReadOnly_2c5eb8d559b68cb5"
    ]
    dev_roles = [
      // "arn:aws:iam::12345:role/AWSReservedSSO_AD-EKS-Developers_ac2b0d744059fcd6"
    ]
    monitoring_roles = [
      // "arn:aws:iam::12345:role/AWSReservedSSO_AD-EKS-Monitoring-Admins_ac2b0d744059fcd6"
    ]
  }

}

variable "node_role_policies" {
  default = []
}

variable "fargate_selector" {
  default = {
    serverless = {
      // role_arn =
    },
  }
}

variable "metrics_server_enabled" {
  default = true
}

variable "node_groups" {
  default = {
    # "t2.micro" = {
    #   instance_types        = ["t2.micro"],
    #   capacity_type         = "ON_DEMAND"
    #   node_disk_size        = 20,
    #   node_desired_capacity = 1,
    #   nodes_max_size        = 1,
    #   nodes_min_size        = 1
    #
    # },
    # "t3.small" = {
    #   instance_types        = ["t3.small"],
    #   capacity_type         = "SPOT"
    #   node_disk_size        = 20,
    #   node_desired_capacity = 1,
    #   nodes_max_size        = 1,
    #   nodes_min_size        = 1
    # },

  }
}
