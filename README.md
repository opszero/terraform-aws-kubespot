<!-- BEGIN_TF_DOCS -->
# Kubespot (AWS)

<img src="http://assets.opszero.com/images/auditkube.png" width="200px" />

Compliance Oriented Kubernetes Setup for AWS.

Kubespot is an open source terraform module that attempts to create a complete
compliance-oriented Kubernetes setup on AWS, Google Cloud and Azure. These add
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

# Cluster Usage

If the infrastructure is using the
[opsZero infrastructure as code](https://github.com/opszero/template-infra) template
then you access the resources like the following:

Add your IAM credentials in `~/.aws/credentials`.

```
[profile_name]
aws_access_key_id=<>key>
aws_secret_access_key=<secret_key>
region=us-west-2
```

```
cd environments/<nameofenv>
make kubeconfig
export KUBECONFIG=./kubeconfig # add to a .zshrc
kubectl get pods
```

# Autoscaler

Kubespot uses [Karpenter](https://karpenter.sh) as the default autoscaler. To
configure the autoscaler we need to create a file like the one below and run:

```sh
kubectl apply -f karpenter.yml
```

```yml
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
spec:
  consolidation:
    enabled: true # If set to true the nodes will minimize to fit the pods
  requirements:
    - key: "karpenter.k8s.aws/instance-category"
      operator: In
      values: ["t", "c", "m"]
    - key: "kubernetes.io/arch"
      operator: In
      values: ["amd64"]
    - key: "karpenter.k8s.aws/instance-cpu"
      operator: In
      values: ["1", "2", "4", "8", "16"]
    - key: "karpenter.k8s.aws/instance-hypervisor"
      operator: In
      values: ["nitro"]
    - key: karpenter.sh/capacity-type
      operator: In
      values: ["spot", "on-demand"]
  limits:
    resources:
      cpu: 200
  provider:
    securityGroupSelector:
      Name: <cluster-name>-node
    subnetSelector:
      Name: <cluster-name>-private
    tags:
      karpenter.sh/discovery: <cluster-name>
  ttlSecondsUntilExpired: 86400 # How long to keep the node before cycling
```

# Cluster Setup

```
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```
# Pro Support

<a href="https://www.opszero.com"><img src="https://assets.opszero.com/images/opszero_11_29_2016.png" width="300px"/></a>

[opsZero provides support](https://www.opszero.com/devops) for our modules including:

- Email support
- Zoom Calls
- Implementation Guidance
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.50.0 |
| <a name="provider_aws.virginia"></a> [aws.virginia](#provider\_aws.virginia) | ~> 4.50.0 |
| <a name="provider_helm"></a> [helm](#provider\_helm) | 2.8.0 |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_controller_version"></a> [alb\_controller\_version](#input\_alb\_controller\_version) | The chart version of the ALB controller helm chart | `string` | `"1.4.4"` | no |
| <a name="input_aws_load_balancer_controller_enabled"></a> [aws\_load\_balancer\_controller\_enabled](#input\_aws\_load\_balancer\_controller\_enabled) | Enable ALB controller by default | `bool` | `true` | no |
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile to use | `string` | n/a | yes |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block used by the VPC | `string` | `"10.2.0.0/16"` | no |
| <a name="input_cidr_block_private_subnet"></a> [cidr\_block\_private\_subnet](#input\_cidr\_block\_private\_subnet) | The CIDR block used by the private subnet | `list` | <pre>[<br>  "10.2.2.0/24",<br>  "10.2.3.0/24"<br>]</pre> | no |
| <a name="input_cidr_block_public_subnet"></a> [cidr\_block\_public\_subnet](#input\_cidr\_block\_public\_subnet) | The CIDR block used by the private subnet | `list` | <pre>[<br>  "10.2.0.0/24",<br>  "10.2.1.0/24"<br>]</pre> | no |
| <a name="input_cluster_logging"></a> [cluster\_logging](#input\_cluster\_logging) | List of the desired control plane logging to enable | `list` | <pre>[<br>  "api",<br>  "audit",<br>  "authenticator",<br>  "controllerManager",<br>  "scheduler"<br>]</pre> | no |
| <a name="input_cluster_private_access"></a> [cluster\_private\_access](#input\_cluster\_private\_access) | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `false` | no |
| <a name="input_cluster_public_access"></a> [cluster\_public\_access](#input\_cluster\_public\_access) | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_cluster_public_access_cidrs"></a> [cluster\_public\_access\_cidrs](#input\_cluster\_public\_access\_cidrs) | List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled | `list` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Desired Kubernetes master version | `string` | `"1.23"` | no |
| <a name="input_csi_secrets_store_enabled"></a> [csi\_secrets\_store\_enabled](#input\_csi\_secrets\_store\_enabled) | Specify whether the CSI driver is enabled on the EKS cluster | `bool` | `false` | no |
| <a name="input_csi_secrets_store_version"></a> [csi\_secrets\_store\_version](#input\_csi\_secrets\_store\_version) | The version of the CSI store helm chart | `string` | `"1.3.2"` | no |
| <a name="input_efs_enabled"></a> [efs\_enabled](#input\_efs\_enabled) | Specify whether the EFS is enabled on the EKS cluster | `bool` | `false` | no |
| <a name="input_eips"></a> [eips](#input\_eips) | List of Elastic IPs | `list` | `[]` | no |
| <a name="input_enable_egress_only_internet_gateway"></a> [enable\_egress\_only\_internet\_gateway](#input\_enable\_egress\_only\_internet\_gateway) | Create an egress-only Internet gateway for your VPC0 | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Enable an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC | `bool` | `false` | no |
| <a name="input_enable_nat"></a> [enable\_nat](#input\_enable\_nat) | Whether the NAT gateway is enabled | `bool` | `true` | no |
| <a name="input_enabled_metrics_asg"></a> [enabled\_metrics\_asg](#input\_enabled\_metrics\_asg) | A list of metrics to collect | `list` | <pre>[<br>  "GroupDesiredCapacity",<br>  "GroupInServiceCapacity",<br>  "GroupInServiceInstances",<br>  "GroupMaxSize",<br>  "GroupMinSize",<br>  "GroupPendingCapacity",<br>  "GroupPendingInstances",<br>  "GroupStandbyCapacity",<br>  "GroupStandbyInstances",<br>  "GroupTerminatingCapacity",<br>  "GroupTerminatingInstances",<br>  "GroupTotalCapacity",<br>  "GroupTotalInstances"<br>]</pre> | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Name of the environment to create AWS resources | `string` | n/a | yes |
| <a name="input_fargate_selector"></a> [fargate\_selector](#input\_fargate\_selector) | Terraform object to create the EKS fargate profiles | `map` | <pre>{<br>  "serverless": {}<br>}</pre> | no |
| <a name="input_govcloud"></a> [govcloud](#input\_govcloud) | Set if the environment is govcloud | `bool` | `false` | no |
| <a name="input_iam_users"></a> [iam\_users](#input\_iam\_users) | List of IAM users | `list` | `[]` | no |
| <a name="input_karpenter_enabled"></a> [karpenter\_enabled](#input\_karpenter\_enabled) | Specify whether the karpenter is enabled | `bool` | `false` | no |
| <a name="input_karpenter_version"></a> [karpenter\_version](#input\_karpenter\_version) | The version of the karpenter helm chart | `string` | `"v0.27.1"` | no |
| <a name="input_legacy_subnet"></a> [legacy\_subnet](#input\_legacy\_subnet) | Specify how the subnets should be created | `bool` | `true` | no |
| <a name="input_metrics_server_version"></a> [metrics\_server\_version](#input\_metrics\_server\_version) | The version of the metric server helm chart | `string` | `"3.9.0"` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `string` | `""` | no |
| <a name="input_node_group_cpu_threshold"></a> [node\_group\_cpu\_threshold](#input\_node\_group\_cpu\_threshold) | The value of the CPU threshold | `string` | `"70"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Terraform object to create the EKS node groups | `map` | `{}` | no |
| <a name="input_node_role_policies"></a> [node\_role\_policies](#input\_node\_role\_policies) | A list of The ARN of the policies you want to attach | `list` | `[]` | no |
| <a name="input_nodes_blue_desired_capacity"></a> [nodes\_blue\_desired\_capacity](#input\_nodes\_blue\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the group | `number` | `0` | no |
| <a name="input_nodes_blue_instance_type"></a> [nodes\_blue\_instance\_type](#input\_nodes\_blue\_instance\_type) | The instance type to use for the instance | `string` | `"t3.micro"` | no |
| <a name="input_nodes_blue_max_instance_lifetime"></a> [nodes\_blue\_max\_instance\_lifetime](#input\_nodes\_blue\_max\_instance\_lifetime) | The maximum amount of time, in seconds, that an instance can be in service | `number` | `604800` | no |
| <a name="input_nodes_blue_max_size"></a> [nodes\_blue\_max\_size](#input\_nodes\_blue\_max\_size) | The maximum size of the Auto Scaling Group | `number` | `0` | no |
| <a name="input_nodes_blue_min_size"></a> [nodes\_blue\_min\_size](#input\_nodes\_blue\_min\_size) | The minimum size of the Auto Scaling Group | `number` | `0` | no |
| <a name="input_nodes_blue_root_device_size"></a> [nodes\_blue\_root\_device\_size](#input\_nodes\_blue\_root\_device\_size) | Size of the volume in gibibytes (GiB) | `string` | `"20"` | no |
| <a name="input_nodes_blue_spot_price"></a> [nodes\_blue\_spot\_price](#input\_nodes\_blue\_spot\_price) | The maximum price to use for reserving spot instances. | `any` | `null` | no |
| <a name="input_nodes_blue_subnet_ids"></a> [nodes\_blue\_subnet\_ids](#input\_nodes\_blue\_subnet\_ids) | A list of subnet IDs to launch resources in | `list` | `[]` | no |
| <a name="input_nodes_green_desired_capacity"></a> [nodes\_green\_desired\_capacity](#input\_nodes\_green\_desired\_capacity) | The number of Amazon EC2 instances that should be running in the group | `number` | `0` | no |
| <a name="input_nodes_green_instance_type"></a> [nodes\_green\_instance\_type](#input\_nodes\_green\_instance\_type) | The instance type to use for the instance | `string` | `"t3.micro"` | no |
| <a name="input_nodes_green_max_instance_lifetime"></a> [nodes\_green\_max\_instance\_lifetime](#input\_nodes\_green\_max\_instance\_lifetime) | The maximum amount of time, in seconds, that an instance can be in service | `number` | `604800` | no |
| <a name="input_nodes_green_max_size"></a> [nodes\_green\_max\_size](#input\_nodes\_green\_max\_size) | The maximum size of the Auto Scaling Group | `number` | `0` | no |
| <a name="input_nodes_green_min_size"></a> [nodes\_green\_min\_size](#input\_nodes\_green\_min\_size) | The minimum size of the Auto Scaling Group | `number` | `0` | no |
| <a name="input_nodes_green_root_device_size"></a> [nodes\_green\_root\_device\_size](#input\_nodes\_green\_root\_device\_size) | Size of the volume in gibibytes (GiB) | `string` | `"20"` | no |
| <a name="input_nodes_green_spot_price"></a> [nodes\_green\_spot\_price](#input\_nodes\_green\_spot\_price) | The maximum price to use for reserving spot instances. | `any` | `null` | no |
| <a name="input_nodes_green_subnet_ids"></a> [nodes\_green\_subnet\_ids](#input\_nodes\_green\_subnet\_ids) | A list of subnet IDs to launch resources in | `list` | `[]` | no |
| <a name="input_nodes_in_public_subnet"></a> [nodes\_in\_public\_subnet](#input\_nodes\_in\_public\_subnet) | INSECURE! Only use this if you want to avoid paying for the NAT. Also set enable\_nat to false | `bool` | `false` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Specifies whether Performance Insights are enabled. Defaults to false | `bool` | `false` | no |
| <a name="input_redis_enabled"></a> [redis\_enabled](#input\_redis\_enabled) | Whether the redis cluster is enabled | `bool` | `false` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | Version number of the cache engine to be used for the cache clusters in this replication group | `string` | `"7.0"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | Instance class of the redis cluster to be used | `string` | `"cache.t4g.micro"` | no |
| <a name="input_redis_num_nodes"></a> [redis\_num\_nodes](#input\_redis\_num\_nodes) | Number of nodes for redis | `number` | `1` | no |
| <a name="input_repos"></a> [repos](#input\_repos) | n/a | `list` | `[]` | no |
| <a name="input_sql_cluster_enabled"></a> [sql\_cluster\_enabled](#input\_sql\_cluster\_enabled) | Whether the sql cluster is enabled | `bool` | `false` | no |
| <a name="input_sql_database_name"></a> [sql\_database\_name](#input\_sql\_database\_name) | The name of the database to create when the DB instance is created | `string` | `""` | no |
| <a name="input_sql_encrypted"></a> [sql\_encrypted](#input\_sql\_encrypted) | Specify whether the DB instance is encrypted | `bool` | `true` | no |
| <a name="input_sql_engine"></a> [sql\_engine](#input\_sql\_engine) | The name of the database engine to be used for this DB cluster | `string` | `"aurora-postgresql"` | no |
| <a name="input_sql_engine_mode"></a> [sql\_engine\_mode](#input\_sql\_engine\_mode) | The database engine mode | `string` | `"provisioned"` | no |
| <a name="input_sql_engine_version"></a> [sql\_engine\_version](#input\_sql\_engine\_version) | The engine version to use | `string` | `"14.3"` | no |
| <a name="input_sql_identifier"></a> [sql\_identifier](#input\_sql\_identifier) | The name of the database | `string` | `""` | no |
| <a name="input_sql_instance_allocated_storage"></a> [sql\_instance\_allocated\_storage](#input\_sql\_instance\_allocated\_storage) | The allocated storage in gibibytes | `number` | `20` | no |
| <a name="input_sql_instance_class"></a> [sql\_instance\_class](#input\_sql\_instance\_class) | The instance type of the RDS instance. | `string` | `"db.t4g.micro"` | no |
| <a name="input_sql_instance_enabled"></a> [sql\_instance\_enabled](#input\_sql\_instance\_enabled) | Whether the sql instance is enabled | `bool` | `false` | no |
| <a name="input_sql_instance_engine"></a> [sql\_instance\_engine](#input\_sql\_instance\_engine) | The database engine to use | `string` | `"postgres"` | no |
| <a name="input_sql_instance_max_allocated_storage"></a> [sql\_instance\_max\_allocated\_storage](#input\_sql\_instance\_max\_allocated\_storage) | the upper limit to which Amazon RDS can automatically scale the storage of the DB instance | `number` | `200` | no |
| <a name="input_sql_master_password"></a> [sql\_master\_password](#input\_sql\_master\_password) | Password for the master DB user | `string` | `""` | no |
| <a name="input_sql_master_username"></a> [sql\_master\_username](#input\_sql\_master\_username) | Username for the master DB user | `string` | `""` | no |
| <a name="input_sql_node_count"></a> [sql\_node\_count](#input\_sql\_node\_count) | The number of instances to be used for this DB cluster | `number` | `0` | no |
| <a name="input_sql_parameter_group_name"></a> [sql\_parameter\_group\_name](#input\_sql\_parameter\_group\_name) | Name of the DB parameter group to associate | `string` | `""` | no |
| <a name="input_sql_rds_multi_az"></a> [sql\_rds\_multi\_az](#input\_sql\_rds\_multi\_az) | Specify if the RDS instance is enabled multi-AZ | `bool` | `false` | no |
| <a name="input_sql_serverless_max"></a> [sql\_serverless\_max](#input\_sql\_serverless\_max) | The maximum capacity for the DB cluster | `number` | `2` | no |
| <a name="input_sql_serverless_min"></a> [sql\_serverless\_min](#input\_sql\_serverless\_min) | The maximum capacity for the DB cluster | `number` | `2` | no |
| <a name="input_sql_serverless_seconds_until_auto_pause"></a> [sql\_serverless\_seconds\_until\_auto\_pause](#input\_sql\_serverless\_seconds\_until\_auto\_pause) | The time, in seconds, before the DB cluster in serverless mode is paused | `number` | `300` | no |
| <a name="input_sql_skip_final_snapshot"></a> [sql\_skip\_final\_snapshot](#input\_sql\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. | `bool` | `true` | no |
| <a name="input_sql_storage_type"></a> [sql\_storage\_type](#input\_sql\_storage\_type) | The allocated storage type for DB Instance | `string` | `"gp3"` | no |
| <a name="input_sql_subnet_group_include_public"></a> [sql\_subnet\_group\_include\_public](#input\_sql\_subnet\_group\_include\_public) | Include public subnets as part of the clusters subnet configuration. | `bool` | `false` | no |
| <a name="input_sso_roles"></a> [sso\_roles](#input\_sso\_roles) | Terraform object of the IAM roles | `map` | <pre>{<br>  "admin_roles": [],<br>  "dev_roles": [],<br>  "monitoring_roles": [],<br>  "readonly_roles": []<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Terraform map to create custom tags for the AWS resources | `map` | `{}` | no |
| <a name="input_vpc_flow_logs_enabled"></a> [vpc\_flow\_logs\_enabled](#input\_vpc\_flow\_logs\_enabled) | Specify whether the vpc flow log is enabled | `bool` | `false` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | AZs for the subnets | `list` | <pre>[<br>  "us-west-2a",<br>  "us-west-2b"<br>]</pre> | no |
## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.nodes_blue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_group.nodes_green](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_log_group.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.database_cpu_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_disk_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.node_group_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.nodes_blue_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.nodes_green_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_egress_only_internet_gateway.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/egress_only_internet_gateway) | resource |
| [aws_eip.eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eks_addon.core](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_fargate_profile.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_fargate_profile) | resource |
| [aws_eks_node_group.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_elasticache_cluster.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_cluster) | resource |
| [aws_elasticache_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/elasticache_subnet_group) | resource |
| [aws_flow_log.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_instance_profile.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_policy.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.efs_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.fargate-AmazonEKSFargatePodExecutionRolePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-EFS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_role_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
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
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster-ingress-node-https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.eks](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node-ingress-cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node-ingress-self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.private_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.public_subnet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [helm_release.aws_efs_csi_driver](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [helm_release.aws_load_balancer](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [helm_release.csi_secrets_store](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
| [helm_release.metrics-server](https://registry.terraform.io/providers/hashicorp/helm/2.8.0/docs/resources/release) | resource |
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
| [null_resource.karpenter_awsnodetemplates_crd](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.karpenter_crd](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ecrpublic_authorization_token.token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecrpublic_authorization_token) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.eks_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [http_http.csi_secrets_store_aws_provider](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [http_http.karpenter_crd](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [tls_certificate.cluster](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster"></a> [eks\_cluster](#output\_eks\_cluster) | n/a |
| <a name="output_eks_cluster_token"></a> [eks\_cluster\_token](#output\_eks\_cluster\_token) | n/a |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | n/a |
| <a name="output_node_role"></a> [node\_role](#output\_node\_role) | n/a |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | n/a |
| <a name="output_private_route_table"></a> [private\_route\_table](#output\_private\_route\_table) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_public_route_table"></a> [public\_route\_table](#output\_public\_route\_table) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_redis_elasticache_subnet_group_name"></a> [redis\_elasticache\_subnet\_group\_name](#output\_redis\_elasticache\_subnet\_group\_name) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
<!-- END_TF_DOCS -->
