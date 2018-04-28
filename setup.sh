#!/bin/sh

read -e -p "Path To Seed: " SEED_PATH
read -p "AWS_PROFILE: " AWS_PROFILE
# aws configure --profile $AWS_PROFILE
echo aws configure --profile $AWS_PROFILE
ruby setup.rb $SEED_PATH $AWS_PROFILE 
# cd auditkube && make build | tee auditkube.log
echo "cd auditkube && make build | tee auditkube.log"

echo "==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:
us-west-2: ami-asdkf123" | tee auditkube.log
AMI=$(tail -n 1 auditkube.log | awk -F " " '{print $2}')
sed -i '' s/GENERATED_AMI/$AMI/ $SEED_PATH/kubernetes/config.json
CLUSTER_DIR=$(cat cluster_dir)
# cd $CLUSTER_DIR && make up
echo "cd $CLUSTER_DIR && make up"

