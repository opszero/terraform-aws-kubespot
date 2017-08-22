#!/bin/bash -ex

AWS_ACCESS_KEY_ID=$1; shift
AWS_SECRECT_ACCCESS_KEY=$1

if [[ -n $AWS_ACCESS_KEY_ID ]]
then
    sudo apt-get update -y
    sudo apt-get install unzip libwww-perl libdatetime-perlthen

    pushd /tmp/
    curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
    unzip CloudWatchMonitoringScripts-1.2.1.zip
    rm CloudWatchMonitoringScripts-1.2.1.zip

    mv aws-scripts-mon /etc
    pushd /etc/aws-scripts-mon

    echo "AWSAccessKeyId=${AWS_ACCESS_KEY_ID}" > awscreds.conf
    echo "AWSSecretKey=${AWS_SECRECT_ACCCESS_KEY}" >> awscreds.conf

    sudo crontab -l > /tmp/new_crontab
    sudo echo "*/5 * * * * /etc/aws-scripts-mon/mon-put-instance-data.pl --mem-used-incl-cache-buff --mem-util --disk-space-util --disk-path=/ --from-cron" >> /tmp/new_crontab
    sudo crontab /tmp/new_crontab
    sudo rm /tmp/new_crontab
else
    echo "Not Installing CloudWatch"
fi
