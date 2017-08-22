#!/bin/bash -ex

ossec_version="2.9.1"

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
cp /home/admin/ossec_preloaded-vars.conf ./etc/preloaded-vars.conf
cat ./etc/preloaded-vars.conf
sudo bash ./install.sh
sudo /var/ossec/bin/ossec-control start
# sudo /var/ossec/bin/ossec-control status

sudo apt-get purge -y build-essential
sudo apt-get autoremove -y

popd
