variable "cluster-name" {
  type = string
}

variable cidr_block {
  default = "10.2.0.0/16"
}

variable "zones" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "eips" {
  default = []
}

variable "ec2_keypair" {
  default = "opszero"
}

variable "aws_profile" {
  default = "opszero"
}

variable "iam_users" {
  default = []
}

variable "repos" {
  default = []
}

variable "nodes_green_instance_type" {
  default = "t2.micro"
}

variable "nodes_green_desired_capacity" {
  default = 1
}

variable "nodes_green_min_size" {
  default = 1
}

variable "nodes_green_max_size" {
  default = 1
}

variable "nodes_blue_instance_type" {
  default = "t2.micro"
}

variable "nodes_blue_desired_capacity" {
  default = 1
}

variable "nodes_blue_min_size" {
  default = 1
}

variable "nodes_blue_max_size" {
  default = 1
}
