provider "aws" {
  # TODO: Change this
  profile = "opszero"
  # TODO: Change this
  region  = "us-west-2"
}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "./kubeconfig"
}

locals {
  # TODO: Change this
  environment_name = "opszero"
}

module "opszero-eks" {
  source = "github.com/opszero/terraform-aws-kubespot"

  # TODO: Change this
  aws_profile = "opszero"
  zones = [
    "eu-west-1a",
    "eu-west-1b"
  ]

  cluster_version  = "1.27"
  environment_name = local.environment_name
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
  nodes_green_max_size         = 1
  nodes_blue_instance_type     = "t3a.small"
  nodes_blue_desired_capacity  = 1
  nodes_blue_min_size          = 1
  nodes_blue_max_size          = 1

  redis_enabled        = false
  sql_cluster_enabled  = false
  sql_instance_enabled = false

  vpc_flow_logs_enabled = false

  efs_enabled = true
}

module "helm-common" {
  source             = "github.com/opszero/terraform-helm-kubespot"
  cert_manager_email = "ops@opszero.com"

  nginx_min_replicas = 1
  nginx_max_replicas = 3
}


resource "aws_ecr_repository" "opszero" {
  name                 = "opszero"
  image_tag_mutability = "MUTABLE"

  # image_scanning_configuration {
  #   scan_on_push = true
  # }
}
