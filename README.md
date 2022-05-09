<!-- BEGIN_TF_DOCS -->
# opsZero Kubespot (AWS)

<img src="http://assets.opszero.com.s3.amazonaws.com/images/auditkube.png" width="200px" />

Compliance Oriented Kubernetes Setup for AWS.

Kubespot is an open source terraform module that attempts to create a complete
compliance-oriented Kubernetes setup on AWS, Google Cloud and Azure.  These add
additional security such as additional system logs, file system monitoring, hard
disk encryption and access control. Further, we setup the managed Redis and SQL
on each of the Cloud providers with limited access to the Kubernetes cluster so
things are further locked down. All of this should lead to setting up a HIPAA /
PCI / SOC2 being made straightforward and repeatable.

This covers how we setup your infrastructure on AWS, Google Cloud and Azure.
These are the three Cloud Providers that we currently support to run Kubernetes.
Further, we use the managed service provided by each of the Cloud Providers.
This document covers everything related to how infrastructure is setup within
each Cloud, how we create an isolated environment for Compliance and the
commonalities between them.

# Tools & Setup

```
brew install kubectl kubernetes-helm awscli terraform
```

# Credentials

Add your IAM credentials in ~/.aws/credentials.

```
[profile_name]
aws_access_key_id=<>key>
aws_secret_access_key=<secret_key>
region=us-west-2
```

# AWS Configuration

```
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

# Network Diagram


## Releases

```sh
TAG=v3.0.1
gh release create $TAG --discussion-category "General"
```

# Support
<a href="https://www.opszero.com"><img src="http://assets.opszero.com.s3.amazonaws.com/images/opszero_11_29_2016.png" width="300px"/></a>

This project is by [opsZero](https://www.opszero.com). We help organizations
migrate to Kubernetes so [reach out](https://www.opszero.com/#contact) if you
need help!

# License

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.7.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_name"></a> [alb\_name](#input\_alb\_name) | n/a | `string` | `"aws-load-balancer-controller"` | no |
| <a name="input_ami_image"></a> [ami\_image](#input\_ami\_image) | n/a | `string` | `""` | no |
| <a name="input_aws_load_balancer_controller_enabled"></a> [aws\_load\_balancer\_controller\_enabled](#input\_aws\_load\_balancer\_controller\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_bastion_ec2_keypair"></a> [bastion\_ec2\_keypair](#input\_bastion\_ec2\_keypair) | n/a | `string` | `"opszero"` | no |
| <a name="input_bastion_eip_enabled"></a> [bastion\_eip\_enabled](#input\_bastion\_eip\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_bastion_enabled"></a> [bastion\_enabled](#input\_bastion\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_bastion_instance_type"></a> [bastion\_instance\_type](#input\_bastion\_instance\_type) | n/a | `string` | `"t3.micro"` | no |
| <a name="input_bastion_volume_size"></a> [bastion\_volume\_size](#input\_bastion\_volume\_size) | n/a | `number` | `20` | no |
| <a name="input_bastion_vpn_allowed_cidrs"></a> [bastion\_vpn\_allowed\_cidrs](#input\_bastion\_vpn\_allowed\_cidrs) | These are the IPs that the bastion and VPN allow connections from. | `list` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block used by the VPC | `string` | `"10.2.0.0/16"` | no |
| <a name="input_cidr_block_private_subnet"></a> [cidr\_block\_private\_subnet](#input\_cidr\_block\_private\_subnet) | The CIDR block used by the private subnet | `list` | <pre>[<br>  "10.2.2.0/24",<br>  "10.2.3.0/24"<br>]</pre> | no |
| <a name="input_cidr_block_public_subnet"></a> [cidr\_block\_public\_subnet](#input\_cidr\_block\_public\_subnet) | The CIDR block used by the private subnet | `list` | <pre>[<br>  "10.2.0.0/24",<br>  "10.2.1.0/24"<br>]</pre> | no |
| <a name="input_cluster_logging"></a> [cluster\_logging](#input\_cluster\_logging) | n/a | `list` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_private_access"></a> [cluster\_private\_access](#input\_cluster\_private\_access) | n/a | `bool` | `false` | no |
| <a name="input_cluster_public_access"></a> [cluster\_public\_access](#input\_cluster\_public\_access) | n/a | `bool` | `true` | no |
| <a name="input_cluster_public_access_cidrs"></a> [cluster\_public\_access\_cidrs](#input\_cluster\_public\_access\_cidrs) | n/a | `list` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | n/a | `string` | `"1.21"` | no |
| <a name="input_csi_secrets_store_enabled"></a> [csi\_secrets\_store\_enabled](#input\_csi\_secrets\_store\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_ec2_keypair"></a> [ec2\_keypair](#input\_ec2\_keypair) | n/a | `string` | `"opszero"` | no |
| <a name="input_efs_enabled"></a> [efs\_enabled](#input\_efs\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_eips"></a> [eips](#input\_eips) | n/a | `list` | `[]` | no |
| <a name="input_eks_guardduty_enabled"></a> [eks\_guardduty\_enabled](#input\_eks\_guardduty\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_enable_egress_only_internet_gateway"></a> [enable\_egress\_only\_internet\_gateway](#input\_enable\_egress\_only\_internet\_gateway) | n/a | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | n/a | `bool` | `false` | no |
| <a name="input_enable_nat"></a> [enable\_nat](#input\_enable\_nat) | n/a | `bool` | `true` | no |
| <a name="input_enabled_metrics_asg"></a> [enabled\_metrics\_asg](#input\_enabled\_metrics\_asg) | n/a | `list` | <pre>[<br>  "GroupDesiredCapacity",<br>  "GroupInServiceCapacity",<br>  "GroupInServiceInstances",<br>  "GroupMaxSize",<br>  "GroupMinSize",<br>  "GroupPendingCapacity",<br>  "GroupPendingInstances",<br>  "GroupStandbyCapacity",<br>  "GroupStandbyInstances",<br>  "GroupTerminatingCapacity",<br>  "GroupTerminatingInstances",<br>  "GroupTotalCapacity",<br>  "GroupTotalInstances"<br>]</pre> | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | n/a | `string` | n/a | yes |
| <a name="input_fargate_selector"></a> [fargate\_selector](#input\_fargate\_selector) | n/a | `map` | <pre>{<br>  "serverless": {}<br>}</pre> | no |
| <a name="input_foxpass_api_key"></a> [foxpass\_api\_key](#input\_foxpass\_api\_key) | the following below are required for setting up the vpn | `string` | `""` | no |
| <a name="input_foxpass_base_dn"></a> [foxpass\_base\_dn](#input\_foxpass\_base\_dn) | n/a | `string` | `""` | no |
| <a name="input_foxpass_bind_pw"></a> [foxpass\_bind\_pw](#input\_foxpass\_bind\_pw) | n/a | `string` | `""` | no |
| <a name="input_foxpass_bind_user"></a> [foxpass\_bind\_user](#input\_foxpass\_bind\_user) | n/a | `string` | `""` | no |
| <a name="input_foxpass_eip_enabled"></a> [foxpass\_eip\_enabled](#input\_foxpass\_eip\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_foxpass_install"></a> [foxpass\_install](#input\_foxpass\_install) | Make this a string to be read in the user-data | `string` | `""` | no |
| <a name="input_foxpass_vpn_psk"></a> [foxpass\_vpn\_psk](#input\_foxpass\_vpn\_psk) | use this for psk generation https://cloud.google.com/vpn/docs/how-to/generating-pre-shared-key | `string` | `""` | no |
| <a name="input_iam_users"></a> [iam\_users](#input\_iam\_users) | n/a | `list` | `[]` | no |
| <a name="input_instance_userdata"></a> [instance\_userdata](#input\_instance\_userdata) | n/a | `string` | `""` | no |
| <a name="input_karpenter_enabled"></a> [karpenter\_enabled](#input\_karpenter\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_karpenter_name"></a> [karpenter\_name](#input\_karpenter\_name) | n/a | `string` | `"karpenter-scaler"` | no |
| <a name="input_karpenter_version"></a> [karpenter\_version](#input\_karpenter\_version) | n/a | `string` | `"v0.7.3"` | no |
| <a name="input_legacy_subnet"></a> [legacy\_subnet](#input\_legacy\_subnet) | n/a | `bool` | `true` | no |
| <a name="input_logdna_ingestion_key"></a> [logdna\_ingestion\_key](#input\_logdna\_ingestion\_key) | n/a | `string` | `""` | no |
| <a name="input_metrics_server_version"></a> [metrics\_server\_version](#input\_metrics\_server\_version) | n/a | `string` | `"3.8.2"` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | n/a | `string` | `""` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | n/a | `map` | `{}` | no |
| <a name="input_node_role_policies"></a> [node\_role\_policies](#input\_node\_role\_policies) | n/a | `list` | `[]` | no |
| <a name="input_nodes_blue_desired_capacity"></a> [nodes\_blue\_desired\_capacity](#input\_nodes\_blue\_desired\_capacity) | n/a | `number` | `0` | no |
| <a name="input_nodes_blue_instance_type"></a> [nodes\_blue\_instance\_type](#input\_nodes\_blue\_instance\_type) | n/a | `string` | `"t3.micro"` | no |
| <a name="input_nodes_blue_max_instance_lifetime"></a> [nodes\_blue\_max\_instance\_lifetime](#input\_nodes\_blue\_max\_instance\_lifetime) | n/a | `number` | `604800` | no |
| <a name="input_nodes_blue_max_size"></a> [nodes\_blue\_max\_size](#input\_nodes\_blue\_max\_size) | n/a | `number` | `0` | no |
| <a name="input_nodes_blue_min_size"></a> [nodes\_blue\_min\_size](#input\_nodes\_blue\_min\_size) | n/a | `number` | `0` | no |
| <a name="input_nodes_blue_root_device_size"></a> [nodes\_blue\_root\_device\_size](#input\_nodes\_blue\_root\_device\_size) | n/a | `string` | `"20"` | no |
| <a name="input_nodes_blue_subnet_ids"></a> [nodes\_blue\_subnet\_ids](#input\_nodes\_blue\_subnet\_ids) | n/a | `list` | `[]` | no |
| <a name="input_nodes_green_desired_capacity"></a> [nodes\_green\_desired\_capacity](#input\_nodes\_green\_desired\_capacity) | n/a | `number` | `0` | no |
| <a name="input_nodes_green_instance_type"></a> [nodes\_green\_instance\_type](#input\_nodes\_green\_instance\_type) | n/a | `string` | `"t3.micro"` | no |
| <a name="input_nodes_green_max_instance_lifetime"></a> [nodes\_green\_max\_instance\_lifetime](#input\_nodes\_green\_max\_instance\_lifetime) | n/a | `number` | `604800` | no |
| <a name="input_nodes_green_max_size"></a> [nodes\_green\_max\_size](#input\_nodes\_green\_max\_size) | n/a | `number` | `0` | no |
| <a name="input_nodes_green_min_size"></a> [nodes\_green\_min\_size](#input\_nodes\_green\_min\_size) | n/a | `number` | `0` | no |
| <a name="input_nodes_green_root_device_size"></a> [nodes\_green\_root\_device\_size](#input\_nodes\_green\_root\_device\_size) | n/a | `string` | `"20"` | no |
| <a name="input_nodes_green_subnet_ids"></a> [nodes\_green\_subnet\_ids](#input\_nodes\_green\_subnet\_ids) | n/a | `list` | `[]` | no |
| <a name="input_nodes_in_public_subnet"></a> [nodes\_in\_public\_subnet](#input\_nodes\_in\_public\_subnet) | INSECURE! Only use this if you want to avoid paying for the NAT. Also set enable\_nat to false | `bool` | `false` | no |
| <a name="input_redis_enabled"></a> [redis\_enabled](#input\_redis\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | n/a | `string` | `"6.x"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | n/a | `string` | `"cache.t3.micro"` | no |
| <a name="input_repos"></a> [repos](#input\_repos) | n/a | `list` | `[]` | no |
| <a name="input_sql_cluster_enabled"></a> [sql\_cluster\_enabled](#input\_sql\_cluster\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_sql_database_name"></a> [sql\_database\_name](#input\_sql\_database\_name) | n/a | `string` | `""` | no |
| <a name="input_sql_encrypted"></a> [sql\_encrypted](#input\_sql\_encrypted) | n/a | `bool` | `true` | no |
| <a name="input_sql_engine"></a> [sql\_engine](#input\_sql\_engine) | n/a | `string` | `"aurora-postgresql"` | no |
| <a name="input_sql_engine_mode"></a> [sql\_engine\_mode](#input\_sql\_engine\_mode) | n/a | `string` | `"serverless"` | no |
| <a name="input_sql_engine_version"></a> [sql\_engine\_version](#input\_sql\_engine\_version) | n/a | `string` | `"12.7"` | no |
| <a name="input_sql_identifier"></a> [sql\_identifier](#input\_sql\_identifier) | The name of the database | `string` | `""` | no |
| <a name="input_sql_instance_allocated_storage"></a> [sql\_instance\_allocated\_storage](#input\_sql\_instance\_allocated\_storage) | n/a | `number` | `20` | no |
| <a name="input_sql_instance_class"></a> [sql\_instance\_class](#input\_sql\_instance\_class) | n/a | `string` | `"db.t3.medium"` | no |
| <a name="input_sql_instance_enabled"></a> [sql\_instance\_enabled](#input\_sql\_instance\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_sql_instance_engine"></a> [sql\_instance\_engine](#input\_sql\_instance\_engine) | n/a | `string` | `"postgres"` | no |
| <a name="input_sql_instance_max_allocated_storage"></a> [sql\_instance\_max\_allocated\_storage](#input\_sql\_instance\_max\_allocated\_storage) | n/a | `number` | `200` | no |
| <a name="input_sql_master_password"></a> [sql\_master\_password](#input\_sql\_master\_password) | n/a | `string` | `""` | no |
| <a name="input_sql_master_username"></a> [sql\_master\_username](#input\_sql\_master\_username) | n/a | `string` | `""` | no |
| <a name="input_sql_node_count"></a> [sql\_node\_count](#input\_sql\_node\_count) | n/a | `number` | `0` | no |
| <a name="input_sql_parameter_group_name"></a> [sql\_parameter\_group\_name](#input\_sql\_parameter\_group\_name) | n/a | `string` | `""` | no |
| <a name="input_sql_rds_multi_az"></a> [sql\_rds\_multi\_az](#input\_sql\_rds\_multi\_az) | n/a | `bool` | `false` | no |
| <a name="input_sql_serverless_max"></a> [sql\_serverless\_max](#input\_sql\_serverless\_max) | n/a | `number` | `2` | no |
| <a name="input_sql_serverless_min"></a> [sql\_serverless\_min](#input\_sql\_serverless\_min) | n/a | `number` | `2` | no |
| <a name="input_sql_serverless_seconds_until_auto_pause"></a> [sql\_serverless\_seconds\_until\_auto\_pause](#input\_sql\_serverless\_seconds\_until\_auto\_pause) | n/a | `number` | `300` | no |
| <a name="input_sso_roles"></a> [sso\_roles](#input\_sso\_roles) | n/a | `map` | <pre>{<br>  "admin_roles": [],<br>  "dev_roles": [],<br>  "monitoring_roles": [],<br>  "readonly_roles": []<br>}</pre> | no |
| <a name="input_vpc_flow_logs_enabled"></a> [vpc\_flow\_logs\_enabled](#input\_vpc\_flow\_logs\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | n/a | `list` | <pre>[<br>  "us-west-2a",<br>  "us-west-2b"<br>]</pre> | no |
## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.nodes_blue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.nodes_green](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_log_group.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.bastion_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_cpu_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_disk_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.nodes_blue_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.nodes_green_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_egress_only_internet_gateway.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/egress_only_internet_gateway) | resource |
| [aws_eip.bastion_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eks_addon.core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_fargate_profile.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_fargate_profile) | resource |
| [aws_eks_node_group.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_elasticache_cluster.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster) | resource |
| [aws_elasticache_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_flow_log.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_guardduty_detector.detector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/guardduty_detector) | resource |
| [aws_iam_instance_profile.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.efs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node_oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.autoscaling](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.autoscaling_oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.karpenter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.aws_node_oidc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.fargate-AmazonEKSFargatePodExecutionRolePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.karpenter_ssm_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-EFS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_role_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_launch_configuration.nodes_blue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_launch_configuration.nodes_green](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_nat_gateway.gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_rds_cluster.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.cluster_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_route.ig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.ipv6](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.bastion](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.bastion_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cluster-ingress-node-https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node-ingress-cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node-ingress-self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [helm_release.aws_efs_csi_driver](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.aws_load_balancer](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.csi_secrets_store](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metrics-server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_cluster_role_binding.eks_admins_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_cluster_role_binding.eks_readonly_binding](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/cluster_role_binding) | resource |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_role.default_eks_admins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role.default_eks_developers](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role.default_eks_monitoring_admins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role.default_eks_readonly](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role) | resource |
| [kubernetes_role_binding.default_eks_admins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_role_binding.default_eks_developers](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_role_binding.default_eks_monitoring_admins](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [kubernetes_role_binding.default_eks_readonly](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/role_binding) | resource |
| [null_resource.csi_secrets_store_aws_provider](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.karpenter_crd](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_ami.foxpass_vpn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.eks_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [http_http.csi_secrets_store_aws_provider](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.karpenter_crd](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [tls_certificate.cluster](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_ca_cert_helm_provider"></a> [eks\_ca\_cert\_helm\_provider](#output\_eks\_ca\_cert\_helm\_provider) | n/a |
| <a name="output_eks_endpoint_helm_provider"></a> [eks\_endpoint\_helm\_provider](#output\_eks\_endpoint\_helm\_provider) | n/a |
| <a name="output_eks_token_helm_provider"></a> [eks\_token\_helm\_provider](#output\_eks\_token\_helm\_provider) | n/a |
| <a name="output_node_role"></a> [node\_role](#output\_node\_role) | n/a |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | n/a |
| <a name="output_private_route_table"></a> [private\_route\_table](#output\_private\_route\_table) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_public_route_table"></a> [public\_route\_table](#output\_public\_route\_table) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_redis_elasticache_subnet_group_name"></a> [redis\_elasticache\_subnet\_group\_name](#output\_redis\_elasticache\_subnet\_group\_name) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->