variable "secret" {}

data "aws_ssm_parameter" "secret" {
  name            = var.secret
  with_decryption = true
}

output "secret_value" {
  value = data.aws_ssm_parameter.secret.value
}
