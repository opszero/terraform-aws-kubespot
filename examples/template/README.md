# opsZero infra-template

infra-template is the infrastructure template used by opsZero. It sets up a common
directory structure and


## Structure

 - `cloudflare`: DNS and Cloudflare Access
 - `environments`: Cloud Kubernetes Clusters, Common Cloud Terraform, Shared Terraform
 - `iam`: Setup IAM & SSO access to clusters.
 - `secrets`: Store and manage secrets.
   - `ssm`: Store secrets in AWS Systems Manager Parameter Store


## Makefile

 - `make fmt`: Run `terraform fmt`
