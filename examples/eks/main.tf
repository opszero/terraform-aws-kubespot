
locals {
  environment_name = "appcensus-dev"
  profile          = "appcensus-staging"
}

provider "aws" {
  region = "us-east-1"
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
  source = "./../../"

  #aws_profile = local.profile
  zones = [
    "us-east-1a",
    "us-east-1b"
  ]

  cluster_version  = "1.27"
  environment_name = local.environment_name
  iam_users = {
    "abhi@opszero.com" = {
      rbac_groups = [
        "system:masters"
      ]
    },
    "bitbucket-deployer" = {
      rbac_groups = [
        "system:masters"
      ]
    },

  }
  cidr_block = "10.3.0.0/16"
  cidr_block_public_subnet = [
    "10.3.0.0/18",
    "10.3.64.0/18",
  ]
  cidr_block_private_subnet = [
    "10.3.128.0/18",
    "10.3.192.0/18",
  ]


  node_group_defaults = {
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 16
          volume_type = "gp3"
          iops        = 3000
          throughput  = 150
          encrypted   = true
        }
      }
    }
  }


  node_groups = {
    "t3a-medium-spot" = {

      instance_types = ["t3a.medium","t3.medium" ]
      capacity_type          = "SPOT"
      min_size              = 1
      max_size              = 1
      desired_size           = 1
      nodes_min_size         = 1
    }
  }

  redis_enabled        = false
  sql_cluster_enabled  = false
  sql_instance_enabled = false

  nat_enabled           = true
  vpc_flow_logs_enabled = false
  efs_enabled           = false
}
#
#module "helm-common" {
#  source             = "github.com/opszero/terraform-helm-kubespot"
#  cert_manager_email = "ops@opszero.com"
#
#  nginx_min_replicas = 1
#  nginx_max_replicas = 3
#}


# resource "aws_ecr_repository" "opszero" {
#   name                 = "opszero"
#   image_tag_mutability = "MUTABLE"

#   # image_scanning_configuration {
#   #   scan_on_push = true
#   # }
# }
