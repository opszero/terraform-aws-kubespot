data "aws_ami" "opszero_eks" {
  most_recent = true

  filter {
    name   = "name"
    values = ["opszero-eks-*"]
  }

  owners = ["self"]
}

data "aws_ssm_paramenter" "eks_ami" {
    name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}

data "aws_ami" "foxpass_vpn" {

  most_recent = true

  filter {
    name   = "name"
    values = ["foxpass-ipsec-vpn *"]
  }
  owners = ["679593333241"]
}
