AWS_PROFILE=profile_name

kubeconfig:
	KUBECONFIG=./kubeconfig aws --profile $(AWS_PROFILE) eks update-kubeconfig --name kubespot-prod1

apply:
	terraform init -get -upgrade && terraform get -update && terraform apply