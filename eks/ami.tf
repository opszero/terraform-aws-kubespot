data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  tags = {
    "KubespotEnvironment" = var.environment_name
  }

}

data "aws_ssm_parameter" "eks_ami" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}

data "aws_ami" "foxpass_vpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["foxpass-ipsec-vpn *"]
  }
  owners = ["679593333241"]

  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}