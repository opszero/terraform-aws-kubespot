provider "aws" {
  region = "us-west-2"
  profile = "personal"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"
    ]
  }


  owners = ["099720109477"]
  # Canonical
}



module "k3s" {
  source = "../../aws/k3s"
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  aws_profile = "personal"
  ec2_keypair = "personal-keypair"
  region = "us-west-2"
}