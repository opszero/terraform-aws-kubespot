<!-- BEGIN_TF_DOCS -->
# Kubespot (AWS)

AWS EKS Setup for PCI-DSS, SOC2, HIPAA

Kubespot is [AWS EKS](https://aws.amazon.com/eks/) customized to add security
postures around SOC2, HIPAA, and PCI compliance. It is distributed as [an open
source terraform module](https://github.com/opszero/terraform-aws-kubespot)
allowing you to run it within your own AWS account without lock-in. Kubespot has
been developed over a half a decade evolving with the AWS EKS distribution and
before that [kops.](https://github.com/kubernetes/kops) It is in use within
multiple startups that have scaled from a couple founders in an apartment to
billion dollar unicorns. By using Kubespot they were able to achieve the
technical requirements for compliance while being able to deploy software fast.

Kubespot is a light wrapper around AWS EKS. The primary changes included in
Kubespot are:

- Locked down with security groups, private subnets and other compliance related requirements.
- Locked down RDS and Elasticache if needed.
- Users have a single Load Balancer through which all requests go through to reduce costs.
- [KEDA](https://keda.sh/) is used for scaling on event metrics such as queue sizes, user requests, CPU, memory or anything else Keda supports.
- [Karpenter](https://karpenter.sh/) is used for autoscaling.
- Instance are lockdown with encryption, and a regular node cycle rate is set.

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
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
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
      nodeClassRef:
        name: default
  disruption:
    consolidationPolicy: WhenUnderutilized
    expireAfter: 2h # 30 * 24h = 720h
---
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: Bottlerocket # Amazon Linux 2
  role: "Karpenter-opszero" # Set the name of the cluster
  subnetSelectorTerms:
    - tags:
        Name: opszero-public
  securityGroupSelectorTerms:
    - tags:
        Name: eks-cluster-sg-opszero-1249901478
```

# Cluster Setup

```
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```

# CIS Kubernetes Benchmark

Note: PodSecurityPolicy (PSP) is deprecated and PodSecurity admission controller
is the new standard. The CIS Benchmark is still using PSP. We have converted
the PSP to the [equivalent new standard](https://kubernetes.io/docs/tasks/configure-pod-container/migrate-from-psp/).

| Control | Recommendation                                                                                           | Level | Status    | Description                                                                                                  |
| ------- | -------------------------------------------------------------------------------------------------------- | ----- | --------- | ------------------------------------------------------------------------------------------------------------ |
| **1**   | **Control Plane Components**                                                                             |       |           |                                                                                                              |
| **2**   | **Control Plane Configuration**                                                                          |       |           |                                                                                                              |
| **2.1** | **Logging**                                                                                              |       |           |                                                                                                              |
| 2.1.1   | Enable audit logs                                                                                        | L1    | Active    | `cluster_logging` is configured                                                                              |
| **3**   | **Worker Nodes**                                                                                         |       |           |                                                                                                              |
| **3.1** | **Worker Node Configuration Files**                                                                      |       |           |                                                                                                              |
| 3.1.1   | Ensure that the kubeconfig file permissions are set to 644 or more restrictive                           | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.1.2   | Ensure that the kubelet kubeconfig file ownership is set to root:root                                    | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.1.3   | Ensure that the kubelet configuration file has permissions set to 644 or more restrictive                | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.1.4   | Ensure that the kubelet configuration file ownership is set to root:root                                 | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| **3.2** | **Kubelet**                                                                                              |       |           |                                                                                                              |
| 3.2.1   | Ensure that the Anonymous Auth is Not Enabled                                                            | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.2   | Ensure that the --authorization-mode argument is not set to AlwaysAllow                                  | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.3   | Ensure that a Client CA File is Configured                                                               | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.4   | Ensure that the --read-only-port is disabled                                                             | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.5   | Ensure that the --streaming-connection-idle-timeout argument is not set to 0                             | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.6   | Ensure that the --protect-kernel-defaults argument is set to true                                        | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.7   | Ensure that the --make-iptables-util-chains argument is set to true                                      | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.8   | Ensure that the --hostname-override argument is not set                                                  | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.9   | Ensure that the --eventRecordQPS argument is set to 0 or a level which ensures appropriate event capture | L2    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.10  | Ensure that the --rotate-certificates argument is not present or is set to true                          | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| 3.2.11  | Ensure that the RotateKubeletServerCertificate argument is set to true                                   | L1    | Won't Fix | Use NodeGroups or Fargate                                                                                    |
| **3.3** | **Container Optimized OS**                                                                               |       |           |                                                                                                              |
| 3.3.1   | Prefer using a container-optimized OS when possible                                                      | L2    | Active    | Bottlerocket ContainerOS is used.                                                                            |
| **4**   | **Policies**                                                                                             |       |           |                                                                                                              |
| **4.1** | **RBAC and Service Accounts**                                                                            |       |           |                                                                                                              |
| 4.1.1   | Ensure that the cluster-admin role is only used where required                                           | L1    | Active    | [Default Configuration](https://github.com/opszero/terraform-aws-kubespot/issues/308)                        |
| 4.1.2   | Minimize access to secrets                                                                               | L1    | Active    | `iam_roles` pass limited RBAC                                                                                |
| 4.1.3   | Minimize wildcard use in Roles and ClusterRoles                                                          | L1    | Manual    | [terraform-kubernetes-rbac](https://github.com/opszero/terraform-kubernetes-rbac) Set role                   |
| 4.1.4   | Minimize access to create pods                                                                           | L1    | Manual    | [terraform-kubernetes-rbac](https://github.com/opszero/terraform-kubernetes-rbac) Limit role with pod create |
| 4.1.5   | Ensure that default service accounts are not actively used                                               | L1    | Manual    | `kubectl patch serviceaccount default -p $'automountServiceAccountToken: false'`                             |
| 4.1.6   | Ensure that Service Account Tokens are only mounted where necessary                                      | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) Default set to false                                             |
| 4.1.7   | Avoid use of system:masters group                                                                        | L1    | Active    | Must manually add users and roles to `system:masters`                                                        |
| 4.1.8   | Limit use of the Bind, Impersonate and Escalate permissions in the Kubernetes cluster                    | L1    | Manual    | Limit users with system:masters role                                                                         |
| **4.2** | **Pod Security Policies**                                                                                |       |           |                                                                                                              |
| 4.2.1   | Minimize the admission of privileged containers                                                          | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) defaultSecurityContext.allowPrivilegeEscalation=false            |
| 4.2.2   | Minimize the admission of containers wishing to share the host process ID namespace                      | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) hostPID defaults to false                                        |
| 4.2.3   | Minimize the admission of containers wishing to share the host IPC namespace                             | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) hostIPC defaults to false                                        |
| 4.2.4   | Minimize the admission of containers wishing to share the host network namespace                         | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) hostNetwork defaults to false                                    |
| 4.2.5   | Minimize the admission of containers with allowPrivilegeEscalation                                       | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) defaultSecurityContext.allowPrivilegeEscalation=false            |
| 4.2.6   | Minimize the admission of root containers                                                                | L2    | Active    | [tiphys](https://github.com/opszero/tiphys) defaultSecurityContext.[runAsNonRoot=true,runAsUser=1001]        |
| 4.2.7   | Minimize the admission of containers with added capabilities                                             | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) defaultSecurityContext.allowPrivilegeEscalation=false            |
| 4.2.8   | Minimize the admission of containers with capabilities assigned                                          | L1    | Active    | [tiphys](https://github.com/opszero/tiphys) defaultSecurityContext.capabilities.drop: ALL                    |
| **4.3** | **CNI Plugin**                                                                                           |       |           |                                                                                                              |
| 4.3.1   | Ensure CNI plugin supports network policies.                                                             | L1    | Manual    | `calico_enabled=true`                                                                                        |
| 4.3.2   | Ensure that all Namespaces have Network Policies defined                                                 | L1    | Manual    | Add Network Policy manually                                                                                  |
| **4.4** | **Secrets Management**                                                                                   |       |           |                                                                                                              |
| 4.4.1   | Prefer using secrets as files over secrets as environment variables                                      | L2    | Active    | [tiphys](https://github.com/opszero/tiphys) writes secrets to file                                           |
| 4.4.2   | Consider external secret storage                                                                         | L2    | Manual    | Pull secrets using AWS Secret Manager.                                                                       |
| **4.5** | **Extensible Admission Control**                                                                         |       |           |                                                                                                              |
| **4.6** | **General Policies**                                                                                     |       |           |                                                                                                              |
| 4.6.1   | Create administrative boundaries between resources using namespaces                                      | L1    | Manul     | [tiphys](https://github.com/opszero/tiphys) deploy on different namespace                                    |
| 4.6.2   | Apply Security Context to Your Pods and Containers                                                       | L2    | Active    | [tiphys](https://github.com/opszero/tiphys) defaultSecurityContext is set                                    |
| 4.6.3   | The default namespace should not be used                                                                 | L2    | Active    | [tiphys](https://github.com/opszero/tiphys) select namespace                                                 |
| **5**   | **Managed services**                                                                                     |       |           |                                                                                                              |
| **5.1** | **Image Registry and Image Scanning**                                                                    |       |           |                                                                                                              |
| 5.1.1   | Ensure Image Vulnerability Scanning using Amazon ECR image scanning or a third party provider            | L1    | Active    | [Example](examples/eks/main.tf#L79)                                                                          |
| 5.1.2   | Minimize user access to Amazon ECR                                                                       | L1    | Active    | [terraform-aws-mrmgr](https://github.com/opszero/terraform-aws-mrmgr)                                        |
| 5.1.3   | Minimize cluster access to read-only for Amazon ECR                                                      | L1    | Active    | [terraform-aws-mrmgr](https://github.com/opszero/terraform-aws-mrmgr) with OIDC                              |
| 5.1.4   | Minimize Container Registries to only those approved                                                     | L2    | Active    | [terraform-aws-mrmgr](https://github.com/opszero/terraform-aws-mrmgr)                                        |
| **5.2** | **Identity and Access Management (IAM)**                                                                 |       |           |                                                                                                              |
| 5.2.1   | Prefer using dedicated EKS Service Accounts                                                              | L1    | Active    | [terraform-aws-mrmgr](https://github.com/opszero/terraform-aws-mrmgr) with OIDC                              |
| **5.3** | **AWS EKS Key Management Service**                                                                       |       |           |                                                                                                              |
| 5.3.1   | Ensure Kubernetes Secrets are encrypted using Customer Master Keys (CMKs) managed in AWS KMS             | L1    | Active    |                                                                                                              |
| **5.4** | **Cluster Networking**                                                                                   |       |           |                                                                                                              |
| 5.4.1   | Restrict Access to the Control Plane Endpoint                                                            | L1    | Active    | Set `cluster_public_access_cidrs`                                                                            |
| 5.4.2   | Ensure clusters are created with Private Endpoint Enabled and Public Access Disabled                     | L2    | Active    | Set `cluster_private_access = true` and `cluster_public_access = false`                                      |
| 5.4.3   | Ensure clusters are created with Private Nodes                                                           | L1    | Active    | Set `enable_nat = true` and set `nodes_in_public_subnet = false`                                             |
| 5.4.4   | Ensure Network Policy is Enabled and set as appropriate                                                  | L1    | Manual    | `calico_enabled=true`                                                                                        |
| 5.4.5   | Encrypt traffic to HTTPS load balancers with TLS certificates                                            | L2    | Active    | [terraform-helm-kubespot](https://github.com/opszero/terraform-helm-kubespot)                                |
| **5.5** | **Authentication and Authorization**                                                                     |       |           |                                                                                                              |
| 5.5.1   | Manage Kubernetes RBAC users with AWS IAM Authenticator for Kubernetes                                   | L2    | Active    | `iam_users` use AWS IAM Authenticator                                                                        |
| **5.6** | **Other Cluster Configurations**                                                                         |       |           |                                                                                                              |
| 5.6.1   | Consider Fargate for running untrusted workloads                                                         | L1    | Active    | Set the `fargate_selector`                                                                                   |
## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_policies"></a> [access\_policies](#input\_access\_policies) | access policies | `list` | `[]` | no |
| <a name="input_alb_controller_version"></a> [alb\_controller\_version](#input\_alb\_controller\_version) | The chart version of the ALB controller helm chart | `string` | `"1.4.4"` | no |
| <a name="input_asg_nodes"></a> [asg\_nodes](#input\_asg\_nodes) | Map of ASG node configurations | <pre>map(object({<br/>    instance_type          = string<br/>    max_instance_lifetime  = number<br/>    nodes_desired_capacity = number<br/>    nodes_max_size         = number<br/>    nodes_min_size         = number<br/>    nodes_in_public_subnet = bool<br/>    node_disk_size         = number<br/>    node_enabled_metrics   = list(string)<br/>    spot_price             = string<br/>    subnet_ids             = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_aws_load_balancer_controller_enabled"></a> [aws\_load\_balancer\_controller\_enabled](#input\_aws\_load\_balancer\_controller\_enabled) | Enable ALB controller by default | `bool` | `true` | no |
| <a name="input_calico_enabled"></a> [calico\_enabled](#input\_calico\_enabled) | Whether calico add-on is installed | `bool` | `false` | no |
| <a name="input_calico_version"></a> [calico\_version](#input\_calico\_version) | The version of the calico helm chart | `string` | `"v3.26.1"` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | The CIDR block used by the VPC | `string` | `"10.2.0.0/16"` | no |
| <a name="input_cidr_block_private_subnet"></a> [cidr\_block\_private\_subnet](#input\_cidr\_block\_private\_subnet) | The CIDR block used by the private subnet | `list` | <pre>[<br/>  "10.2.2.0/24",<br/>  "10.2.3.0/24"<br/>]</pre> | no |
| <a name="input_cidr_block_public_subnet"></a> [cidr\_block\_public\_subnet](#input\_cidr\_block\_public\_subnet) | The CIDR block used by the private subnet | `list` | <pre>[<br/>  "10.2.0.0/24",<br/>  "10.2.1.0/24"<br/>]</pre> | no |
| <a name="input_cloudwatch_observability_config"></a> [cloudwatch\_observability\_config](#input\_cloudwatch\_observability\_config) | Configuration values for the amazon-cloudwatch-observability addon | `string` | `null` | no |
| <a name="input_cloudwatch_observability_enabled"></a> [cloudwatch\_observability\_enabled](#input\_cloudwatch\_observability\_enabled) | Enable or disable the CloudWatch Observability Add-on for EKS | `bool` | `false` | no |
| <a name="input_cloudwatch_pod_logs_enabled"></a> [cloudwatch\_pod\_logs\_enabled](#input\_cloudwatch\_pod\_logs\_enabled) | Stream EKS pod logs to cloudwatch | `bool` | `false` | no |
| <a name="input_cloudwatch_retention_in_days"></a> [cloudwatch\_retention\_in\_days](#input\_cloudwatch\_retention\_in\_days) | How long to keep CloudWatch logs in days | `number` | `30` | no |
| <a name="input_cluster_authentication_mode"></a> [cluster\_authentication\_mode](#input\_cluster\_authentication\_mode) | Desired Kubernetes authentication. API or API\_AND\_CONFIG\_MAP | `string` | `"API"` | no |
| <a name="input_cluster_encryption_config"></a> [cluster\_encryption\_config](#input\_cluster\_encryption\_config) | Cluster Encryption Config Resources to encrypt, e.g. ['secrets'] | `list(any)` | <pre>[<br/>  "secrets"<br/>]</pre> | no |
| <a name="input_cluster_kms_policy"></a> [cluster\_kms\_policy](#input\_cluster\_kms\_policy) | Cluster Encryption Config KMS Key Resource argument - key policy | `string` | `null` | no |
| <a name="input_cluster_logging"></a> [cluster\_logging](#input\_cluster\_logging) | List of the desired control plane logging to enable. https://docs.aws.amazon.com/eks/latest/userguide/control-plane-logs.html | `list` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_cluster_private_access"></a> [cluster\_private\_access](#input\_cluster\_private\_access) | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_cluster_public_access"></a> [cluster\_public\_access](#input\_cluster\_public\_access) | Whether the Amazon EKS private API server endpoint is enabled | `bool` | `true` | no |
| <a name="input_cluster_public_access_cidrs"></a> [cluster\_public\_access\_cidrs](#input\_cluster\_public\_access\_cidrs) | List of CIDR blocks. Indicates which CIDR blocks can access the Amazon EKS public API server endpoint when enabled | `list` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Desired Kubernetes master version | `string` | `"1.30"` | no |
| <a name="input_csi_enabled_namespaces"></a> [csi\_enabled\_namespaces](#input\_csi\_enabled\_namespaces) | n/a | `list(string)` | `[]` | no |
| <a name="input_csi_secrets_store_enabled"></a> [csi\_secrets\_store\_enabled](#input\_csi\_secrets\_store\_enabled) | Specify whether the CSI driver is enabled on the EKS cluster | `bool` | `false` | no |
| <a name="input_csi_secrets_store_version"></a> [csi\_secrets\_store\_version](#input\_csi\_secrets\_store\_version) | The version of the CSI store helm chart | `string` | `"1.4.6"` | no |
| <a name="input_efs_enabled"></a> [efs\_enabled](#input\_efs\_enabled) | Specify whether the EFS is enabled on the EKS cluster | `bool` | `false` | no |
| <a name="input_eips"></a> [eips](#input\_eips) | List of Elastic IPs | `list` | `[]` | no |
| <a name="input_eks_auto_mode_enabled"></a> [eks\_auto\_mode\_enabled](#input\_eks\_auto\_mode\_enabled) | Enable Auto Mode for EKS cluster | `bool` | `false` | no |
| <a name="input_enable_egress_only_internet_gateway"></a> [enable\_egress\_only\_internet\_gateway](#input\_enable\_egress\_only\_internet\_gateway) | Create an egress-only Internet gateway for your VPC0 | `bool` | `false` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Enable an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC | `bool` | `false` | no |
| <a name="input_environment_name"></a> [environment\_name](#input\_environment\_name) | Name of the environment to create AWS resources | `string` | `"testing"` | no |
| <a name="input_fargate_selector"></a> [fargate\_selector](#input\_fargate\_selector) | Terraform object to create the EKS fargate profiles | `map` | <pre>{<br/>  "serverless": {}<br/>}</pre> | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | Terraform object of the IAM roles | `map` | `{}` | no |
| <a name="input_iam_users"></a> [iam\_users](#input\_iam\_users) | List of IAM users | `list` | `[]` | no |
| <a name="input_karpenter_ami_family"></a> [karpenter\_ami\_family](#input\_karpenter\_ami\_family) | AMI family to use for the EC2 Node Class. Possible values: AL2 or Bottlerocket | `string` | `"Bottlerocket"` | no |
| <a name="input_karpenter_enabled"></a> [karpenter\_enabled](#input\_karpenter\_enabled) | Specify whether the karpenter is enabled | `bool` | `false` | no |
| <a name="input_karpenter_version"></a> [karpenter\_version](#input\_karpenter\_version) | The version of the karpenter helm chart | `string` | `"1.7.1"` | no |
| <a name="input_metrics_server_version"></a> [metrics\_server\_version](#input\_metrics\_server\_version) | The version of the metric server helm chart | `string` | `"3.11.0"` | no |
| <a name="input_nat_enabled"></a> [nat\_enabled](#input\_nat\_enabled) | Whether the NAT gateway is enabled | `bool` | `true` | no |
| <a name="input_node_group_cpu_threshold"></a> [node\_group\_cpu\_threshold](#input\_node\_group\_cpu\_threshold) | The value of the CPU threshold | `string` | `"70"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Terraform object to create the EKS node groups | `map` | `{}` | no |
| <a name="input_node_role_policies"></a> [node\_role\_policies](#input\_node\_role\_policies) | A list of The ARN of the policies you want to attach | `list` | `[]` | no |
| <a name="input_redis_enabled"></a> [redis\_enabled](#input\_redis\_enabled) | Whether the redis cluster is enabled | `bool` | `false` | no |
| <a name="input_redis_engine_version"></a> [redis\_engine\_version](#input\_redis\_engine\_version) | Version number of the cache engine to be used for the cache clusters in this replication group | `string` | `"7.1"` | no |
| <a name="input_redis_node_type"></a> [redis\_node\_type](#input\_redis\_node\_type) | Instance class of the redis cluster to be used | `string` | `"cache.t4g.micro"` | no |
| <a name="input_redis_num_nodes"></a> [redis\_num\_nodes](#input\_redis\_num\_nodes) | Number of nodes for redis | `number` | `1` | no |
| <a name="input_s3_csi_bucket_names"></a> [s3\_csi\_bucket\_names](#input\_s3\_csi\_bucket\_names) | The name of the S3 bucket for the CSI driver | `list(string)` | <pre>[<br/>  ""<br/>]</pre> | no |
| <a name="input_s3_csi_driver_enabled"></a> [s3\_csi\_driver\_enabled](#input\_s3\_csi\_driver\_enabled) | Enable or disable the S3 CSI driver | `bool` | `false` | no |
| <a name="input_sql_cluster_enabled"></a> [sql\_cluster\_enabled](#input\_sql\_cluster\_enabled) | Whether the sql cluster is enabled | `bool` | `false` | no |
| <a name="input_sql_cluster_monitoring_interval"></a> [sql\_cluster\_monitoring\_interval](#input\_sql\_cluster\_monitoring\_interval) | Monitoring Interval for SQL Cluster | `any` | `null` | no |
| <a name="input_sql_cluster_monitoring_role_arn"></a> [sql\_cluster\_monitoring\_role\_arn](#input\_sql\_cluster\_monitoring\_role\_arn) | The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs | `any` | `null` | no |
| <a name="input_sql_database_name"></a> [sql\_database\_name](#input\_sql\_database\_name) | The name of the database to create when the DB instance is created | `string` | `""` | no |
| <a name="input_sql_encrypted"></a> [sql\_encrypted](#input\_sql\_encrypted) | Specify whether the DB instance is encrypted | `bool` | `true` | no |
| <a name="input_sql_engine"></a> [sql\_engine](#input\_sql\_engine) | The name of the database engine to be used for this DB cluster | `string` | `"aurora-postgresql"` | no |
| <a name="input_sql_engine_mode"></a> [sql\_engine\_mode](#input\_sql\_engine\_mode) | The database engine mode | `string` | `"provisioned"` | no |
| <a name="input_sql_engine_version"></a> [sql\_engine\_version](#input\_sql\_engine\_version) | The SQL engine version to use | `string` | `"15.3"` | no |
| <a name="input_sql_iam_auth_enabled"></a> [sql\_iam\_auth\_enabled](#input\_sql\_iam\_auth\_enabled) | Specifies whether or not mappings of IAM accounts to database accounts is enabled | `bool` | `true` | no |
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
| <a name="input_sql_performance_insights_enabled"></a> [sql\_performance\_insights\_enabled](#input\_sql\_performance\_insights\_enabled) | Specifies whether Performance Insights are enabled. Defaults to false | `bool` | `false` | no |
| <a name="input_sql_rds_multi_az"></a> [sql\_rds\_multi\_az](#input\_sql\_rds\_multi\_az) | Specify if the RDS instance is enabled multi-AZ | `bool` | `false` | no |
| <a name="input_sql_serverless_seconds_until_auto_pause"></a> [sql\_serverless\_seconds\_until\_auto\_pause](#input\_sql\_serverless\_seconds\_until\_auto\_pause) | The time, in seconds, before the DB cluster in serverless mode is paused | `number` | `300` | no |
| <a name="input_sql_skip_final_snapshot"></a> [sql\_skip\_final\_snapshot](#input\_sql\_skip\_final\_snapshot) | Determines whether a final DB snapshot is created before the DB instance is deleted. | `bool` | `false` | no |
| <a name="input_sql_storage_type"></a> [sql\_storage\_type](#input\_sql\_storage\_type) | The allocated storage type for DB Instance | `string` | `"gp3"` | no |
| <a name="input_sql_subnet_group_include_public"></a> [sql\_subnet\_group\_include\_public](#input\_sql\_subnet\_group\_include\_public) | Include public subnets as part of the clusters subnet configuration. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Terraform map to create custom tags for the AWS resources | `map` | `{}` | no |
| <a name="input_vpc_flow_logs_enabled"></a> [vpc\_flow\_logs\_enabled](#input\_vpc\_flow\_logs\_enabled) | Specify whether the vpc flow log is enabled | `bool` | `false` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | AZs for the subnets | `list` | <pre>[<br/>  "us-west-2a",<br/>  "us-west-2b"<br/>]</pre> | no |
## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.asg_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_cloudwatch_log_group.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_metric_alarm.asg_nodes_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_cpu_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_cpu_database-rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_disk_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database4](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_free_disk_database5](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_mysql](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_postgres](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_io_rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.node_group_cpu_threshold](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_subnet_group.default](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_egress_only_internet_gateway.egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/egress_only_internet_gateway) | resource |
| [aws_eip.eips](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eks_access_entry.entries](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association.policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
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
| [aws_iam_policy.eks_pod_logs_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.secrets_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.fargate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.secrets_manager_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.vpc](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cloudwatch_observability](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster-AmazonEKSServicePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSBlockStoragePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSComputePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSLoadBalancingPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_AmazonEKSNetworkingPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.csi](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.fargate-AmazonEKSFargatePodExecutionRolePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodeMinimalPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_eks_pod_logs_to_cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_role_policies](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.secrets_manager_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_internet_gateway.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_key.cloudwatch_log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_kms_key.cluster_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_launch_configuration.asg_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration) | resource |
| [aws_launch_template.encrypted_launch_template](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
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
| [helm_release.aws_load_balancer](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.calico](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.csi_secrets_store](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.karpenter_crd](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [helm_release.metrics-server](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_config_map.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_config_map.fluent_bit_cluster_info](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map) | resource |
| [kubernetes_namespace.amazon_cloudwatch](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [kubernetes_service_account.efs_csi_controller_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.efs_csi_node_sa](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [kubernetes_service_account.main](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service_account) | resource |
| [null_resource.csi_secrets_store_aws_provider](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.delete_aws_node](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.karpenter_ec2_node_class_apply](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_eks_cluster_auth.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster_auth) | data source |
| [aws_iam_policy.ssm_managed_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.cloudwatch](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.trust_relationship](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.amis](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [http_http.csi_secrets_store_aws_provider](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [tls_certificate.cluster](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_eks_cluster"></a> [eks\_cluster](#output\_eks\_cluster) | n/a |
| <a name="output_eks_cluster_oidc_provider_arn"></a> [eks\_cluster\_oidc\_provider\_arn](#output\_eks\_cluster\_oidc\_provider\_arn) | n/a |
| <a name="output_eks_cluster_token"></a> [eks\_cluster\_token](#output\_eks\_cluster\_token) | n/a |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | n/a |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | n/a |
| <a name="output_node_role"></a> [node\_role](#output\_node\_role) | n/a |
| <a name="output_node_security_group_id"></a> [node\_security\_group\_id](#output\_node\_security\_group\_id) | n/a |
| <a name="output_private_route_table"></a> [private\_route\_table](#output\_private\_route\_table) | n/a |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | n/a |
| <a name="output_public_route_table"></a> [public\_route\_table](#output\_public\_route\_table) | n/a |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | n/a |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | n/a |
# 🚀 Built by opsZero!

<a href="https://opszero.com"><img src="https://opszero.com/img/common/opsZero-Logo-Large.webp" width="300px"/></a>

[opsZero](https://opszero.com) provides software and consulting for Cloud + AI. With our decade plus of experience scaling some of the world’s most innovative companies we have developed deep expertise in Kubernetes, DevOps, FinOps, and Compliance.

Our software and consulting solutions enable organizations to:

- migrate workloads to the Cloud
- setup compliance frameworks including SOC2, HIPAA, PCI-DSS, ITAR, FedRamp, CMMC, and more.
- FinOps solutions to reduce the cost of running Cloud workloads
- Kubernetes optimized for web scale and AI workloads
- finding underutilized Cloud resources
- setting up custom AI training and delivery
- building data integrations and scrapers
- modernizing onto modern ARM based processors

We do this with a high-touch support model where you:

- Get access to us on Slack, Microsoft Teams or Email
- Get 24/7 coverage of your infrastructure
- Get an accelerated migration to Kubernetes

Please [schedule a call](https://calendly.com/opszero-llc/discovery) if you need support.

<br/><br/>

<div style="display: block">
  <img src="https://opszero.com/img/common/aws-advanced.png" alt="AWS Advanced Tier" width="150px" >
  <img src="https://opszero.com/img/common/aws-devops-competency.png" alt="AWS DevOps Competency" width="150px" >
  <img src="https://opszero.com/img/common/aws-eks.png" alt="AWS EKS Delivery" width="150px" >
  <img src="https://opszero.com/img/common/aws-public-sector.png" alt="AWS Public Sector" width="150px" >
</div>
<!-- END_TF_DOCS -->
