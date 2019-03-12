#!/bin/bash

if [[ -z $LOGDNA_AGENT_KEY  ]]
then
    echo "Not Installing LogDNA."
else
    echo "Installing LogDNA."

    echo "deb http://repo.logdna.com stable main" | sudo tee /etc/apt/sources.list.d/logdna.list
    wget -O- https://s3.amazonaws.com/repo.logdna.com/logdna.gpg | sudo apt-key add -
    sudo apt-get update
    sudo apt-get install -y logdna-agent
    sudo logdna-agent -k $LOGDNA_AGENT_KEY
    sudo update-rc.d logdna-agent defaults
    sudo /etc/init.d/logdna-agent start
fi