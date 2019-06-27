resource "aws_eip" "vpn_eip" {
  instance = aws_instance.vpn[0].id
  vpc      = true
}

resource "aws_instance" "vpn" {
  ami   = data.aws_ami.foxpass_vpn.id
  count = var.foxpass_api_key != "" ? 1 : 0

  instance_type = "t2.micro"

  key_name                    = var.ec2_keypair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids = [
  aws_security_group.node.id]
  user_data = <<SCRIPT
#!/bin/bash -xe
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

file="/config.json"

if [ -f $file ] ; then
  rm $file
fi
touch $file
cat <<EOF > $file
{
  "psk": "${var.vpn_psk}",
  "dns_primary": "8.8.8.8",
  "dns_secondary": "8.8.4.4",
  "local_cidr": "10.11.12.0/24",
  "foxpass_api_key": "${var.foxpass_api_key}",
  "require_groups" : [],
  "name":"opszero-vpn-config"
}
EOF

/opt/bin/config.py $file

SCRIPT

  tags = {
    Name = "${var.cluster-name}-vpn"
  }
}

