variable "aws_profile" {
  type        = string
  description = "AWS profile to use"
}

variable "environment_name" {
  type        = string
  description = "Name of the environment to create AWS resources"
}

variable "cluster_version" {
  default     = "1.23"
  description = "Desired Kubernetes master version"
}

variable "aws_load_balancer_controller_enabled" {
  default     = true
  description = "Enable ALB controller by default"
}

variable "cluster_logging" {
  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  description = " List of the desired control plane logging to enable"
}

variable "cluster_private_access" {
  default     = false
  description = "Whether the Amazon EKS private API server endpoint is enabled"
}

variable "cluster_public_access" {
  default     = true
  description = "Whether the Amazon EKS private API server endpoint is enabled"
}

variable "cluster_public_access_cidrs" {
  default     = ["0.0.0.0/0"]
  description = "List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled"
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
  default     = false
  description = "Enable an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC"
}

variable "enable_nat" {
  default     = true
  description = "Whether the NAT gateway is enabled"
}

variable "enable_egress_only_internet_gateway" {
  default     = false
  description = "Create an egress-only Internet gateway for your VPC0"
}

variable "zones" {
  default     = ["us-west-2a", "us-west-2b"]
  description = "AZs for the subnets"
}

variable "eips" {
  default     = []
  description = "List of Elastic IPs"
}

variable "iam_users" {
  default     = []
  description = "List of IAM users"
}

variable "repos" {
  default = []
}

variable "nodes_in_public_subnet" {
  default     = false
  description = "INSECURE! Only use this if you want to avoid paying for the NAT. Also set enable_nat to false"
}

variable "nodes_green_subnet_ids" {
  default     = []
  description = "A list of subnet IDs to launch resources in"
}

variable "nodes_green_instance_type" {
  default     = "t3.micro"
  description = "The instance type to use for the instance"
}

variable "nodes_green_root_device_size" {
  default     = "20"
  description = "Size of the volume in gibibytes (GiB)"
}

variable "nodes_green_desired_capacity" {
  default     = 0
  description = "The number of Amazon EC2 instances that should be running in the group"
}

variable "nodes_green_min_size" {
  default     = 0
  description = "The minimum size of the Auto Scaling Group"
}

variable "nodes_green_max_size" {
  default     = 0
  description = "The maximum size of the Auto Scaling Group"
}

variable "nodes_green_max_instance_lifetime" {
  default     = 604800 // Default to 7 days
  description = "The maximum amount of time, in seconds, that an instance can be in service"
}

variable "nodes_blue_instance_type" {
  default     = "t3.micro"
  description = "The instance type to use for the instance"
}

variable "nodes_blue_root_device_size" {
  default     = "20"
  description = "Size of the volume in gibibytes (GiB)"
}

variable "nodes_blue_subnet_ids" {
  default     = []
  description = "A list of subnet IDs to launch resources in"
}

variable "nodes_blue_desired_capacity" {
  default     = 0
  description = "The number of Amazon EC2 instances that should be running in the group"
}

variable "nodes_blue_min_size" {
  default     = 0
  description = "The minimum size of the Auto Scaling Group"
}

variable "nodes_blue_max_size" {
  default     = 0
  description = "The maximum size of the Auto Scaling Group"
}

variable "nodes_blue_max_instance_lifetime" {
  default     = 604800 // Default to 7 days
  description = "The maximum amount of time, in seconds, that an instance can be in service"
}

variable "redis_enabled" {
  default     = false
  description = "Whether the redis cluster is enabled"
}

variable "redis_node_type" {
  default     = "cache.t4g.micro"
  description = "Instance class of the redis cluster to be used"
}

variable "redis_engine_version" {
  default     = "7.0"
  description = "Version number of the cache engine to be used for the cache clusters in this replication group"
}

variable "redis_num_nodes" {
  default     = 1
  description = "Number of nodes for redis"
}

variable "sql_cluster_enabled" {
  default     = false
  description = "Whether the sql cluster is enabled"
}

variable "sql_rds_multi_az" {
  default     = false
  description = "Specify if the RDS instance is enabled multi-AZ"
}

variable "sql_engine" {
  default     = "aurora-postgresql"
  description = "The name of the database engine to be used for this DB cluster"
}

variable "sql_engine_mode" {
  default     = "provisioned"
  description = "The database engine mode"
}

variable "sql_node_count" {
  default     = 0
  description = "The number of instances to be used for this DB cluster"
}

variable "sql_instance_class" {
  default     = "db.t4g.micro"
  description = "The instance type of the RDS instance."
}

variable "sql_database_name" {
  default     = ""
  description = "The name of the database to create when the DB instance is created"
}

variable "sql_master_username" {
  default     = ""
  description = "Username for the master DB user"
}

variable "sql_master_password" {
  default     = ""
  description = "Password for the master DB user"
}

variable "sql_serverless_min" {
  default     = 2
  description = "The maximum capacity for the DB cluster"
}

variable "sql_skip_final_snapshot" {
  default     = true
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted."
}

variable "sql_serverless_max" {
  default     = 2
  description = "The maximum capacity for the DB cluster"
}

variable "sql_serverless_seconds_until_auto_pause" {
  default     = 300
  description = "The time, in seconds, before the DB cluster in serverless mode is paused"
}

variable "sql_instance_enabled" {
  default     = false
  description = "Whether the sql instance is enabled"
}

variable "sql_instance_engine" {
  default     = "postgres"
  description = "The database engine to use"
}

variable "sql_subnet_group_include_public" {
  description = "Include public subnets as part of the clusters subnet configuration."
  default     = false
}

variable "sql_instance_allocated_storage" {
  default     = 20
  description = "The allocated storage in gibibytes"
}

variable "sql_storage_type" {
  default     = "gp3"
  description = "The allocated storage type for DB Instance"
}

variable "sql_instance_max_allocated_storage" {
  default     = 200
  description = "the upper limit to which Amazon RDS can automatically scale the storage of the DB instance"
}

variable "sql_engine_version" {
  default     = "14.3"
  description = "The engine version to use"
}

variable "sql_encrypted" {
  default     = true
  description = "Specify whether the DB instance is encrypted"
}

variable "sql_identifier" {
  description = "The name of the database"
  default     = ""
}

variable "sql_parameter_group_name" {
  default     = ""
  description = "Name of the DB parameter group to associate"
}

variable "monitoring_role_arn" {
  default     = ""
  description = " The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
}

variable "enabled_metrics_asg" {
  description = "A list of metrics to collect"
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
  default     = false
  description = "Specify whether the vpc flow log is enabled"
}

variable "efs_enabled" {
  default     = false
  description = "Specify whether the EFS is enabled on the EKS cluster"
}

variable "sso_roles" {
  default = {
    admin_roles = [
      // "arn:${local.partition}:iam::12345:role/AWSReservedSSO_AD-EKS-Admins_b2abd90bad1696ac"
    ]
    readonly_roles = [
      // "arn:${local.partition}:iam::12345:role/AWSReservedSSO_AD-EKS-ReadOnly_2c5eb8d559b68cb5"
    ]
    dev_roles = [
      // "arn:${local.partition}:iam::12345:role/AWSReservedSSO_AD-EKS-Developers_ac2b0d744059fcd6"
    ]
    monitoring_roles = [
      // "arn:${local.partition}:iam::12345:role/AWSReservedSSO_AD-EKS-Monitoring-Admins_ac2b0d744059fcd6"
    ]
  }
  description = "Terraform object of the IAM roles"
}

variable "node_role_policies" {
  default     = []
  description = "A list of The ARN of the policies you want to attach"
}

variable "fargate_selector" {
  default = {
    serverless = {
      // role_arn =
    },
  }
  description = "Terraform object to create the EKS fargate profiles"
}

variable "metrics_server_version" {
  default     = "3.9.0"
  description = "The version of the metric server helm chart"
}

variable "node_groups" {
  description = "Terraform object to create the EKS node groups"
  default = {
    # "t2.micro" = {
    #   instance_types        = ["t2.micro"],
    #   capacity_type         = "ON_DEMAND"
    #   nodes_in_public_subnet = false,
    #   subnet_ids = [],
    #   node_disk_size        = 20,
    #   node_desired_capacity = 1,
    #   nodes_max_size        = 1,
    #   nodes_min_size        = 1
    #
    # },
    # "t3.small" = {
    #   instance_types        = ["t3.small"],
    #   capacity_type         = "SPOT"
    #   nodes_in_public_subnet = true,
    #   node_disk_size        = 20,
    #   node_desired_capacity = 1,
    #   nodes_max_size        = 1,
    #   nodes_min_size        = 1
    # },

  }
}

variable "node_group_cpu_threshold" {
  default     = "70"
  description = "The value of the CPU threshold"
}

variable "karpenter_enabled" {
  default     = false
  description = "Specify whether the karpenter is enabled"
}

variable "karpenter_version" {
  default     = "v0.27.1"
  description = "The version of the karpenter helm chart"
}

variable "legacy_subnet" {
  default     = true
  description = "Specify how the subnets should be created"
}

variable "csi_secrets_store_enabled" {
  default     = false
  description = "Specify whether the CSI driver is enabled on the EKS cluster"
}

variable "csi_secrets_store_version" {
  default     = "1.3.2"
  description = "The version of the CSI store helm chart"
}

variable "tags" {
  description = "Terraform map to create custom tags for the AWS resources"
  default     = {}
}

variable "alb_controller_version" {
  type        = string
  description = "The chart version of the ALB controller helm chart"
  default     = "1.4.4"
}


variable "govcloud" {
  type        = bool
  description = "Set if the environment is govcloud"
  default     = false
}

variable "nodes_green_spot_price" {
  default     = null
  description = "The maximum price to use for reserving spot instances."
}

variable "nodes_blue_spot_price" {
  default     = null
  description = "The maximum price to use for reserving spot instances."
}

variable "performance_insights_enabled" {
  default     = false
  description = " Specifies whether Performance Insights are enabled. Defaults to false"
}

