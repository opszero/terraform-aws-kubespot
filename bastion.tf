resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  vpc      = true
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.opszero_eks.id
  instance_type = "t2.micro"

  key_name                    = var.ec2_keypair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public
  vpc_security_group_ids      = [aws_security_group.node.id]

  tags = {
    Name = "${var.cluster-name}-bastion"
  }
}

# resource "aws_security_group_rule" "opszero_workstation" {
#   cidr_blocks       = ["${}"]
#   description       = "Allow workstation to communicate with the cluster API Server"
#   from_port         = 443
#   protocol          = "tcp"
#   security_group_id = "${aws_security_group.cluster.id}"
#   to_port           = 443
#   type              = "ingress"
# }
