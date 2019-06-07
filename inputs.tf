variable "cluster-name" {
  type = "string"
}

variable "zones" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "eips" {
  default = [
    "eipalloc-9ae756a6",          # 50.112.60.170
    "eipalloc-03faf6bf327775571", # 54.71.95.225
  ]
}

variable "db_vpc_id" {
  default = "vpc-03000c64"
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
