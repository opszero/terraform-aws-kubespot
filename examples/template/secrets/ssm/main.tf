provider "aws" {
  alias = "ssm"
  profile = "<profile>"
  region  = "us-east-1"
}


variable "secret" {}

data "aws_ssm_parameter" "secret" {
  provider        = aws.ssm
  name            = var.secret
  with_decryption = true
}

output "secret_value" {
  value = data.aws_ssm_parameter.secret.value
}
