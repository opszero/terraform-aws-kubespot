data "aws_ami" "foxpass_vpn" {
  most_recent = true

  filter {
    name   = "name"
    values = ["foxpass-ipsec-vpn *"]
  }
  owners = ["679593333241"]

  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}