release: aws-marketplace

aws-marketplace:
	# Need to remove encryption to put on AWS Marketplace
	cat image.json | jq '.builders[].encrypt_boot=false' > aws-marketplace.json
	# Build Image with Packer for AWS Marketplace
	AWS_REGION=us-east-2 \
	AWS_ACCESS_KEY=$(shell aws configure get opszero.aws_access_key_id) \
	AWS_SECRET_KEY=$(shell aws configure get opszero.aws_secret_access_key) \
	packer build aws-marketplace.json
