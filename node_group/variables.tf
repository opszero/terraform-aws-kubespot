#Module      : LABEL
#Description : Terraform label module variables.
variable "name" {
  type        = string
  default     = ""
  description = "Name  (e.g. `app` or `cluster`)."
}

variable "environment" {
  type        = string
  default     = ""
  description = "Environment (e.g. `prod`, `dev`, `staging`)."
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Additional tags (e.g. map(`BusinessUnit`,`XYZ`)."
}


variable "enabled" {
  type        = bool
  default     = true
  description = "Whether to create the resources. Set to `false` to prevent the module from creating any resources."
}

variable "cluster_name" {
  description = "Name of associated EKS cluster"
  type        = string
  default     = null
}

#-----------------------------------------------------------Launch_Template---------------------------------------------------------

variable "launch_template_description" {
  type        = string
  default     = null
  description = "Description of the launch template"
}

variable "ebs_optimized" {
  type        = bool
  default     = null
  description = "If true, the launched EC2 instance(s) will be EBS-optimized"
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "The AMI from which to launch the instance. If not supplied, EKS will use its own default image"
}

variable "key_name" {
  description = "The key name that should be used for the instance(s)"
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default     = []
}

variable "launch_template_default_version" {
  description = "Default version of the launch template"
  type        = string
  default     = null
}

variable "update_launch_template_default_version" {
  description = "Whether to update the launch templates default version on each update. Conflicts with `launch_template_default_version`"
  type        = bool
  default     = true
}

variable "disable_api_termination" {
  description = "If true, enables EC2 instance termination protection"
  type        = bool
  default     = null
}

variable "kernel_id" {
  description = "The kernel ID"
  type        = string
  default     = null
}

variable "ram_disk_id" {
  description = "The ID of the ram disk"
  type        = string
  default     = null
}

variable "block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type        = any
  default     = {}
}

variable "capacity_reservation_specification" {
  description = "Targeting for EC2 capacity reservations"
  type        = any
  default     = null
}

variable "cpu_options" {
  description = "The CPU options for the instance"
  type        = map(string)
  default     = null
}

variable "credit_specification" {
  description = "Customize the credit specification of the instance"
  type        = map(string)
  default     = null
}

variable "elastic_gpu_specifications" {
  description = "The elastic GPU to attach to the instance"
  type        = map(string)
  default     = null
}

variable "elastic_inference_accelerator" {
  description = "Configuration block containing an Elastic Inference Accelerator to attach to the instance"
  type        = map(string)
  default     = null
}

variable "enclave_options" {
  description = "Enable Nitro Enclaves on launched instances"
  type        = map(string)
  default     = null
}

variable "instance_market_options" {
  description = "The market (purchasing) option for the instance"
  type        = any
  default     = null
}

variable "license_specifications" {
  description = "A list of license specifications to associate with"
  type        = map(string)
  default     = null
}

variable "metadata_options" {
  description = "Customize the metadata options for the instance"
  type        = map(string)
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
}

variable "kms_key_id" {
  type        = string
  default     = null
  description = "The KMS ID of EBS volume"
}


variable "enable_monitoring" {
  description = "Enables/disables detailed monitoring"
  type        = bool
  default     = false
}

variable "network_interfaces" {
  description = "Customize network interfaces to be attached at instance boot time"
  type        = list(any)
  default     = []
}

variable "placement" {
  description = "The placement of the instance"
  type        = map(string)
  default     = null
}

variable "launch_template_tags" {
  description = "A map of additional tags to add to the tag_specifications of launch template created"
  type        = map(string)
  default     = {}
}

#EKS_Managed_Node_Group

variable "subnet_ids" {
  description = "Identifiers of EC2 Subnets to associate with the EKS Node Group. These subnets must have the following resource tag: `kubernetes.io/cluster/CLUSTER_NAME`"
  type        = list(string)
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances/nodes"
  type        = number
  default     = 0
}

variable "max_size" {
  description = "Maximum number of instances/nodes"
  type        = number
  default     = 3
}

variable "desired_size" {
  description = "Desired number of instances/nodes"
  type        = number
  default     = 1
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Valid values are `AL2_x86_64`, `AL2_x86_64_GPU`, `AL2_ARM_64`, `CUSTOM`, `BOTTLEROCKET_ARM_64`, `BOTTLEROCKET_x86_64`"
  type        = string
  default     = null
}

variable "ami_release_version" {
  description = "AMI version of the EKS Node Group. Defaults to latest version for Kubernetes version"
  type        = string
  default     = null
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: `ON_DEMAND`, `SPOT`"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size in GiB for nodes. Defaults to `20`"
  type        = number
  default     = null
}

variable "force_update_version" {
  description = "Force version update if existing pods are unable to be drained due to a pod disruption budget issue"
  type        = bool
  default     = null
}

variable "iam_role_arn" {
  type        = string
  default     = ""
  description = ""
}


variable "instance_types" {
  description = "Set of instance types associated with the EKS Node Group. Defaults to `[\"t3.medium\"]`"
  type        = list(string)
  default     = null
}

variable "labels" {
  description = "Key-value map of Kubernetes labels. Only labels that are applied with the EKS API are managed by this argument. Other Kubernetes labels applied to the EKS Node Group will not be managed"
  type        = map(string)
  default     = null
}

variable "cluster_version" {
  description = "Kubernetes version. Defaults to EKS Cluster Kubernetes version"
  type        = string
  default     = null
}

variable "remote_access" {
  description = "Configuration block with remote access settings"
  type        = any
  default     = {}
}

variable "taints" {
  description = "The Kubernetes taints to be applied to the nodes in the node group. Maximum of 50 taints per node group"
  type        = any
  default     = {}
}

variable "update_config" {
  description = "Configuration block of settings for max unavailable resources during node group updates"
  type        = map(string)
  default     = {}
}

variable "timeouts" {
  description = "Create, update, and delete timeout configurations for the node group"
  type        = map(string)
  default     = {}
}

variable "before_cluster_joining_userdata" {
  type        = string
  default     = ""
  description = "Additional commands to execute on each worker node before joining the EKS cluster (before executing the `bootstrap.sh` script). For more info, see https://kubedex.com/90-days-of-aws-eks-in-test"
}

#-----------------------------------------------ASG-Schedule----------------------------------------------------------------

variable "create_schedule" {
  description = "Determines whether to create autoscaling group schedule or not"
  type        = bool
  default     = true
}

variable "schedules" {
  description = "Map of autoscaling group schedule to create"
  type        = map(any)
  default     = {}
}

#-----------------------------------------------ASG-Schedule----------------------------------------------------------------

variable "node_group_cpu_threshold" {
  default     = "70"
  description = "The value of the CPU threshold"
}