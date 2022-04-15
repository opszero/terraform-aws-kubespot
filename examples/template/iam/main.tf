provider "aws" {
  profile = "<profile>"
  region  = "us-west-2"
}

terraform {
  backend "s3" {
    bucket  = "opszero-<profile>-terraform-tfstate"
    region  = "us-east-1"
    profile = "<profile>"
    encrypt = "true"

    key = "iam"
  }
}

data "aws_caller_identity" "current" {}


module "users" {
  source         = "github.com/opszero/iam/aws"
  prefix         = "<Company>"
  aws_account_id = data.aws_caller_identity.current.account_id

  users = {
    "opszero" = ["administrators"]
  }
}
