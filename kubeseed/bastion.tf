resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  vpc      = true
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.opszero_eks.id
  instance_type = "t2.micro"

  key_name                    = var.ec2_keypair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.node.id]

  tags = {
    Name = "${var.cluster-name}-bastion"
  }
}
