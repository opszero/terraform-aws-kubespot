resource "aws_eip" "vpn_eip" {
  count    = var.foxpass_api_key != "" ? 1 : 0
  instance = aws_instance.vpn.0.id
  vpc      = true
}

resource "aws_security_group" "vpn" {
  name        = "${var.environment_name}-vpn"
  description = "Security group for vpn of the cluster"
  vpc_id      = aws_vpc.vpc.id
  count       = var.foxpass_api_key != "" ? 1 : 0
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  ingress {
    from_port = 500
    protocol  = "udp"
    to_port   = 500
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = [
    "0.0.0.0/0"]

  }
  ingress {
    from_port = 0
    protocol  = "50"
    to_port   = 0
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  ingress {
    from_port = 4500
    protocol  = "udp"
    to_port   = 4500
    cidr_blocks = [
    "0.0.0.0/0"]
  }
  ingress {
    from_port = 1701
    protocol  = "udp"
    to_port   = 1701
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  tags = {
    "Name"                                          = "${var.environment_name}-vpn"
    "kubernetes.io/cluster/${var.environment_name}" = "owned"
  }
}

resource "aws_instance" "vpn" {
  ami   = data.aws_ami.foxpass_vpn.id
  count = var.foxpass_api_key != "" ? 1 : 0

  instance_type = "t3.micro"

  key_name                    = var.ec2_keypair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids = [
    aws_security_group.vpn[0].id
  ]
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
  "psk": "${var.foxpass_vpn_psk}",
  "dns_primary": "8.8.8.8",
  "dns_secondary": "8.8.4.4",
  "local_cidr": "10.11.12.0/24",
  "foxpass_api_key": "${var.foxpass_api_key}",
  "require_groups" : [],
  "name":"opszero-vpn-config"
}
EOF

sleep 15

/opt/bin/config.py $file


if [[ ${var.logdna_ingestion_key} == ""  ]]
then
    echo "Not Installing LogDNA."
else
    echo "deb https://repo.logdna.com stable main" | sudo tee /etc/apt/sources.list.d/logdna.list
    wget -O- https://repo.logdna.com/logdna.gpg | sudo apt-key add -
    apt-get update
    apt-get install logdna-agent < "/dev/null" # this line needed for copy/paste
    logdna-agent -k ${var.logdna_ingestion_key} # this is your unique Ingestion Key
    # /var/log is monitored/added by default (recursively), optionally add more dirs with:
    # sudo logdna-agent -d /path/to/log/folders
    # You can configure the agent to tag your hosts with:
    # sudo logdna-agent -t mytag,myothertag
    update-rc.d logdna-agent defaults
    /etc/init.d/logdna-agent start
fi



SCRIPT

  tags = {
    Name = "${var.environment_name}-vpn"
  }
}

