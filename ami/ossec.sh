#!/bin/bash -ex

ossec_version="2.9.1"

sudo apt-get update -y && sudo apt-get install -y build-essential

cd /tmp/
wget https://github.com/ossec/ossec-hids/archive/${ossec_version}.tar.gz
wget https://github.com/ossec/ossec-hids/releases/download/${ossec_version}/ossec-hids-${ossec_version}.tar.gz.asc
gpg --verify ossec-hids-${ossec_version}.tar.gz.asc ${ossec_version}.tar.gz
mv ${ossec_version}.tar.gz ossec-hids-${ossec_version}.tar.gz
checksum=$(sha1sum ossec-hids-${ossec_version}.tar.gz | cut -d" " -f1)

if [ $checksum == $ossec_checksum ]
then
    tar xfz ossec-hids-${ossec_version}.tar.gz
    cd ossec-hids-${ossec_version}
    cp /home/admin/ossec_preloaded-vars.conf ./etc/preloaded-vars.conf
    cat ./etc/preloaded-vars.conf
    sudo bash ./install.sh
    sudo /var/ossec/bin/ossec-control start
    # sudo /var/ossec/bin/ossec-control status

    # curl http://169.254.169.254/latest/meta-data/local-ipv4
else
    "Wrong checksum. Download again or check if file has been tampered with."
fi

sudo apt-get purge -y build-essential
sudo apt-get autoremove -y