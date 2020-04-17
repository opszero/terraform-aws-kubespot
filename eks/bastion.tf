resource "aws_instance" "bastion" {
  count = var.bastion_enabled ? 1 : 0

  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  key_name                    = var.ec2_keypair
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.node.id]

  tags = {
    Name = "${var.environment_name}-bastion"
  }
  user_data = <<SCRIPT
wget -q -O - https://updates.atomicorp.com/installers/atomic | bash
apt-get update -y
apt-get install -y ossec-hids-server ossec-hids-agent

if [[ ${var.foxpass_install} = "" ]]
then
    echo "Not Installing Foxpass"
else
    pushd /tmp
    wget https://raw.githubusercontent.com/foxpass/foxpass-setup/master/linux/amzn/2.0/foxpass_setup.py
    python foxpass_setup.py --base-dn {{user `foxpass_base_dn`}}  --bind-user {{user `foxpass_bind_user`}} --bind-pw {{user `foxpass_bind_pw`}} --api-key {{user `foxpass_api_key`}}; fi"
    popd
end

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

  root_block_device {
    encrypted = true
  }
}
