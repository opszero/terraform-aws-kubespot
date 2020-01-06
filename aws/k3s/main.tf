provider "aws" {
  profile = var.aws_profile
  region = var.region
}

locals {
  user_data = <<DATA
#cloud-config

runcmd:
 - apt install curl systemd cgroup-bin cgroup-lite libcgroup1 -y
 - curl -sfL https://get.k3s.io | sh -
final_message: "Opsero k3s successfully created, after $UPTIME seconds"

DATA
}

resource "aws_security_group" "k3s" {
  name = "k3s-rules"
}

resource "aws_security_group_rule" "http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s.id
}

resource "aws_security_group_rule" "https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s.id
}

resource "aws_security_group_rule" "ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s.id
}


resource "aws_security_group_rule" "allow_all_out" {
  type = "egress"
  from_port = 0
  to_port = 65535
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s.id
}

resource "aws_instance" "cluster" {
  ami = var.ami
  instance_type = var.instance_type
  associate_public_ip_address = true
  user_data = local.user_data
  key_name = var.ec2_keypair
  security_groups = [
    aws_security_group.k3s.name]
}