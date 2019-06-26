resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  vpc = true
}

resource "aws_instance" "bastion" {
  //  ami = data.aws_ami.opszero_eks.id
  ami = "ami-049aea444f70407b8"
  instance_type = "t2.micro"

  key_name = var.ec2_keypair
  associate_public_ip_address = true
  subnet_id = aws_subnet.public[0].id
  vpc_security_group_ids = [
    aws_security_group.node.id]

  tags = {
    Name = "${var.cluster-name}-bastion"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    host = aws_instance.bastion.public_ip
    private_key = file("opszero.pem")
  }
  provisioner "file" {
    destination = "$HOME/config.json"
    content = <<CONFIG
{
  "psk": "${var.vpn_psk}",
  "dns_primary": "8.8.8.8",
  "dns_secondary": "8.8.4.4",
  "local_cidr": "10.11.12.0/24",
  "foxpass_api_key": "${var.foxpass_api_key}",
  "require_groups" : [],
  "name":"opszero-vpn-config"
}
CONFIG
  }
  provisioner "remote-exec" {
    inline = [
      "sudo /opt/bin/config.py $HOME/config.json"
    ]
  }
}