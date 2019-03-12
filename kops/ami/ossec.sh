#!/bin/bash

ossec_version="3.1.0"

sudo apt-get update -y && sudo apt-get install -y build-essential

pushd /tmp/
wget https://github.com/ossec/ossec-hids/archive/${ossec_version}.tar.gz
wget https://github.com/ossec/ossec-hids/releases/download/${ossec_version}/ossec-hids-${ossec_version}.tar.gz.asc
wget https://ossec.github.io/files/OSSEC-ARCHIVE-KEY.asc
gpg --import OSSEC-ARCHIVE-KEY.asc
gpg --verify ossec-hids-${ossec_version}.tar.gz.asc ${ossec_version}.tar.gz
mv ${ossec_version}.tar.gz ossec-hids-${ossec_version}.tar.gz

tar xfz ossec-hids-${ossec_version}.tar.gz
cd ossec-hids-${ossec_version}
cp /home/ubuntu/ossec_preloaded-vars.conf ./etc/preloaded-vars.conf
cat ./etc/preloaded-vars.conf
sudo bash ./install.sh
sudo /var/ossec/bin/ossec-control start
# sudo /var/ossec/bin/ossec-control status

sudo apt-get purge -y build-essential
sudo apt-get autoremove -y

popd


# # Add Apt sources.lst
# wget -q -O - https://updates.atomicorp.com/installers/atomic | sudo bash

# # Update apt data
# sudo apt-get update -y

# # Server
# sudo apt-get install -y ossec-hids-server

# # Agent
# sudo apt-get install -y ossec-hids-agent

# cp /home/ubuntu/ossec_preloaded-vars.conf ./etc/preloaded-vars.conf
# cat ./etc/preloaded-vars.conf
