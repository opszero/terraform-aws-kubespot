data "aws_ssm_parameter" "bottlerocket_image_id" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.eks_cluster_version}/x86_64/latest/image_id"
}

module "eks_mng_bottlerocket_custom_ami" {
  source = "github.com/terraform-aws-modules/terraform-aws-eks/modules/_user_data"

  platform = "bottlerocket"

  cluster_name        = var.eks_cluster.name
  cluster_endpoint    = var.eks_cluster.endpoint
  cluster_auth_base64 = var.eks_cluster.certificate_authority[0].data

  enable_bootstrap_user_data = true

  bootstrap_extra_args = <<-EOT
    # extra args added
    [settings.kernel]
    lockdown = "integrity"
  EOT
}

resource "aws_launch_template" "this" {
  name_prefix = var.eks_cluster.name
  image_id    = data.aws_ssm_parameter.bottlerocket_image_id.value

  monitoring {
    enabled = true
  }

  user_data = module.eks_mng_bottlerocket_custom_ami.user_data

  block_device_mappings {
    device_name = "/dev/xvda"
    no_device   = true
    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
    }
  }

  block_device_mappings {
    device_name = "/dev/xvdb"
    no_device   = true
    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp3"
      encrypted             = true
    }
  }
}
