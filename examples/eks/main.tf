provider "aws" {
  # TODO: Change this
  profile = "opszero"
  # TODO: Change this
  region = "us-west-2"
}

locals {
  environment_name = "appcensus-dev"
  profile          = "appcensus-staging"
}

provider "aws" {
  profile = local.profile
  region  = "us-east-1"
}

provider "helm" {
  kubernetes {
    config_path = "./kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "./kubeconfig"
}

module "opszero-eks" {
  source = "github.com/opszero/terraform-aws-kubespot"

  aws_profile = local.profile
  zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  cluster_version  = "1.27"
  environment_name = local.environment_name
  iam_users = [
    "abhi@opszero.com",
    "bitbucket-deployer",
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

  node_groups = {
    "t3a-medium-spot" = {
      instance_types = [
        "t3a.medium",
      ]
      capacity_type          = "SPOT"
      nodes_in_public_subnet = false
      node_disk_size         = 20,
      node_desired_capacity  = 3,
      nodes_max_size         = 3,
      nodes_min_size         = 3
    }
  }

  redis_enabled        = false
  sql_cluster_enabled  = false
  sql_instance_enabled = false

  nat_enabled           = true
  vpc_flow_logs_enabled = false
  efs_enabled           = false
}

module "helm-common" {
  source             = "github.com/opszero/terraform-helm-kubespot"
  cert_manager_email = "ops@opszero.com"

  nginx_min_replicas = 1
  nginx_max_replicas = 3
}


# resource "aws_ecr_repository" "opszero" {
#   name                 = "opszero"
#   image_tag_mutability = "MUTABLE"

#   # image_scanning_configuration {
#   #   scan_on_push = true
#   # }
# }
