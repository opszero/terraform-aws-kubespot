provider "aws" {
  profile = "awsprofile"
  region  = "us-east-1"
}

locals {
  environment_name = "kubespot-prod1"
}

module "opszero-eks" {
  source = "github.com/opszero/kubespot//eks"

  zones = [
    "us-east-1c",
    "us-east-1d"
  ]

  cluster_version  = "1.21"
  environment_name = var.environment_name
  ec2_keypair      = "opszero"
  iam_users = [
    "opszero",
  ]

  cidr_block = "10.3.0.0/16"
  cidr_block_public_subnet = [
    "10.3.0.0/18",
    "10.3.64.0/18",
  ]
  cidr_block_private_subnet = [
    "10.3.128.0/18",
    "10.3.192.0/18",
  ]

  enable_nat             = false
  nodes_in_public_subnet = true

  nodes_green_instance_type    = "t3a.small"
  nodes_green_desired_capacity = 1
  nodes_green_min_size         = 1
  nodes_green_max_size         = 2
  nodes_blue_instance_type     = "t3a.small"
  nodes_blue_desired_capacity  = 0
  nodes_blue_min_size          = 0
  nodes_blue_max_size          = 0

  bastion_enabled     = false
  bastion_eip_enabled = false

  bastion_vpn_allowed_cidrs = []

  redis_enabled        = false
  sql_cluster_enabled  = false
  sql_instance_enabled = false

  vpc_flow_logs_enabled = false

  efs_enabled = true
}


resource "aws_ecr_repository" "kubespot" {
  name                 = "kubespot"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
