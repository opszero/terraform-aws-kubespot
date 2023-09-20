fmt:
	terraform fmt -recursive

system6-apply:
	ops-prod product_load_support_description terraform-aws-kubespot ./usage.md
