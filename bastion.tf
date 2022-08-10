resource "aws_eip" "bastion_eip" {
  count    = var.bastion_enabled && var.bastion_eip_enabled ? 1 : 0
  instance = aws_instance.bastion.0.id
  vpc      = true
  tags     = local.tags
}

resource "aws_cloudwatch_metric_alarm" "bastion_cpu_threshold" {
  count = var.bastion_enabled ? 1 : 0

  alarm_name                = "${var.environment_name}-bastion-cpu-threshold"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "300"
  statistic                 = "Average"
  threshold                 = "80"
  alarm_description         = "This metric monitors ec2 cpu utilization"
  insufficient_data_actions = []

  dimensions = {
    InstanceId = aws_instance.bastion[0].id
  }

  tags = local.tags
}

resource "aws_security_group" "bastion" {
  name        = "${var.environment_name}-bastion"
  description = "Security group for bastion"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    "Name"                = "${var.environment_name}-bastion"
    "KubespotEnvironment" = var.environment_name
  })
}

resource "aws_security_group_rule" "bastion_ssh" {
  for_each          = toset(var.bastion_vpn_allowed_cidrs)
  cidr_blocks       = [each.key]
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.bastion.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_instance" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.bastion_instance_type

  key_name                    = var.bastion_ec2_keypair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.node.id, aws_security_group.bastion.id]

  monitoring = true

  tags = merge(local.tags, {
    "Name"                = "${var.environment_name}-bastion"
    "KubespotEnvironment" = var.environment_name
  })
  user_data = <<SCRIPT
#!/bin/bash

#wget -q -O - https://updates.atomicorp.com/installers/atomic | bash
apt-get update -y
apt-get install -y python-minimal python-urllib3

if [[ "${var.logdna_ingestion_key}" = ""  ]]
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


${var.instance_userdata}

echo 'echo "Ciphers aes128-ctr,aes192-ctr,aes256-ctr" | tee -a /etc/ssh/sshd_config' | tee -a /etc/rc.local
echo 'echo "MACs hmac-sha1,hmac-sha2-256,hmac-sha2-512" | tee -a /etc/ssh/sshd_config' | tee -a /etc/rc.local
echo 'systemctl reload ssh.service' | tee -a /etc/rc.local
echo 'exit 0' | tee -a /etc/rc.local
chmod +x /etc/rc.local
SCRIPT

  root_block_device {
    encrypted   = true
    volume_size = var.bastion_volume_size
  }
}
