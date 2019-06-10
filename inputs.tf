variable "cluster-name" {
  type = "string"
}

variable "zones" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "eips" {
  default = []
}

variable "db_vpc_id" {
  default = ""
}

variable "vpc_peer_name" {
  default = "eks-to-dbs"
}

variable "ec2_keypair" {
  default = "opszero"
}

variable "aws_profile" {
  default = "opszero"
}

variable "iam_users" {
  type    = list(string)
  default = []
}
