data "aws_ami" "opszero_eks" {
  most_recent = true

  filter {
    name   = "name"
    values = ["opszero-eks-*"]
  }

  owners = ["self"]
}
