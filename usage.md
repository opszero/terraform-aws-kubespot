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

# CIS Kubernetes Benchmark

|---------|----------------------------------------------------------------------------------------------------------|-------|----------------|-----------------------------------|
| Control | Recommendation                                                                                           | Level | Status         | Description                       |
|---------|----------------------------------------------------------------------------------------------------------|-------|----------------|-----------------------------------|
| 1       | Control Plane Components                                                                                 |       |                |                                   |
| 2       | Control Plane Configuration                                                                              |       |                |                                   |
| 2.1     | Logging                                                                                                  |       |                |                                   |
| 2.1.1   | Enable audit logs                                                                                        | L1    | Active         | Add to `cluster_logging`          |
| 3       | Worker Nodes                                                                                             |       |                |                                   |
| 3.1     | Worker Node Configuration Files                                                                          |       |                |                                   |
| 3.1.1   | Ensure that the kubeconfig file permissions are set to 644 or more restrictive                           | L1    | Not Applicable | Bottlerocket ContainerOS is used. |
| 3.1.2   | Ensure that the kubelet kubeconfig file ownership is set to root:root                                    | L1    | Not Applicable | Bottlerocket ContainerOS is used. |
| 3.1.3   | Ensure that the kubelet configuration file has permissions set to 644 or more restrictive                | L1    | Not Applicable | Bottlerocket ContainerOS is used. |
| 3.1.4   | Ensure that the kubelet configuration file ownership is set to root:root                                 | L1    | Not Applicable | Bottlerocket ContainerOS is used. |
| 3.2     | Kubelet                                                                                                  |       |                |                                   |
| 3.2.1   | Ensure that the Anonymous Auth is Not Enabled                                                            | L1    | Remediate      |                                   |
| 3.2.2   | Ensure that the --authorization-mode argument is not set to AlwaysAllow                                  | L1    | Remediate      |                                   |
| 3.2.3   | Ensure that a Client CA File is Configured                                                               | L1    | Remediate      |                                   |
| 3.2.4   | Ensure that the --read-only-port is disabled                                                             | L1    | Remediate      |                                   |
| 3.2.5   | Ensure that the --streaming-connection-idle-timeout argument is not set to 0                             | L1    | Remediate      |                                   |
| 3.2.6   | Ensure that the --protect-kernel-defaults argument is set to true                                        | L1    | Remediate      |                                   |
| 3.2.7   | Ensure that the --make-iptables-util-chains argument is set to true                                      | L1    | Remediate      |                                   |
| 3.2.8   | Ensure that the --hostname-override argument is not set                                                  | L1    | Remediate      |                                   |
| 3.2.9   | Ensure that the --eventRecordQPS argument is set to 0 or a level which ensures appropriate event capture | L2    |                |                                   |
| 3.2.10  | Ensure that the --rotate-certificates argument is not present or is set to true                          | L1    |                |                                   |
| 3.2.11  | Ensure that the RotateKubeletServerCertificate argument is set to true                                   | L1    |                |                                   |
| 3.3     | Container Optimized OS                                                                                   |       |                |                                   |
| 3.3.1   | Prefer using a container-optimized OS when possible                                                      | L2    | Active         | Bottlerocket ContainerOS is used. |
| 4       | Policies                                                                                                 |       |                |                                   |
| 4.1     | RBAC and Service Accounts                                                                                |       |                |                                   |
| 4.1.1   | Ensure that the cluster-admin role is only used where required                                           | L1    | Remidiate      |                                   |
| 4.1.2   | Minimize access to secrets                                                                               | L1    |                |                                   |
| 4.1.3   | Minimize wildcard use in Roles and ClusterRoles                                                          | L1    |                |                                   |
| 4.1.4   | Minimize access to create pods                                                                           | L1    |                |                                   |
| 4.1.5   | Ensure that default service accounts are not actively used                                               | L1    |                |                                   |
| 4.1.6   | Ensure that Service Account Tokens are only mounted where necessary                                      | L1    |                |                                   |
| 4.1.7   | Avoid use of system:masters group                                                                        | L1    |                |                                   |
| 4.1.8   | Limit use of the Bind, Impersonate and Escalate permissions in the Kubernetes cluster                    | L1    |                |                                   |
| 4.2     | Pod Security Policies                                                                                    |       |                |                                   |
| 4.2.1   | Minimize the admission of privileged containers                                                          | L1    |                |                                   |
| 4.2.2   | Minimize the admission of containers wishing to share the host process ID namespace                      | L1    |                |                                   |
| 4.2.3   | Minimize the admission of containers wishing to share the host IPC namespace                             | L1    |                |                                   |
| 4.2.4   | Minimize the admission of containers wishing to share the host network namespace                         | L1    |                |                                   |
| 4.2.5   | Minimize the admission of containers with allowPrivilegeEscalation                                       | L1    |                |                                   |
| 4.2.6   | Minimize the admission of root containers                                                                | L2    |                |                                   |
| 4.2.7   | Minimize the admission of containers with added capabilities                                             | L1    |                |                                   |
| 4.2.8   | Minimize the admission of containers with capabilities assigned                                          | L1    |                |                                   |
| 4.3     | CNI Plugin                                                                                               |       |                |                                   |
| 4.3.1   | Ensure CNI plugin supports network policies.                                                             | L1    |                |                                   |
| 4.3.2   | Ensure that all Namespaces have Network Policies defined                                                 | L1    |                |                                   |
| 4.4     | Secrets Management                                                                                       |       |                |                                   |
| 4.4.1   | Prefer using secrets as files over secrets as environment variables                                      | L2    |                |                                   |
| 4.4.2   | Consider external secret storage                                                                         | L2    |                |                                   |
| 4.5     | Extensible Admission Control                                                                             |       |                |                                   |
| 4.6     | General Policies                                                                                         |       |                |                                   |
| 4.6.1   | Create administrative boundaries between resources using namespaces                                      | L1    |                |                                   |
| 4.6.2   | Apply Security Context to Your Pods and Containers                                                       | L2    |                |                                   |
| 4.6.3   | The default namespace should not be used                                                                 | L2    |                |                                   |
| 5       | Managed services                                                                                         |       |                |                                   |
| 5.1     | Image Registry and Image Scanning                                                                        |       |                |                                   |
| 5.1.1   | Ensure Image Vulnerability Scanning using Amazon ECR image scanning or a third party provider            | L1    |                |                                   |
| 5.1.2   | Minimize user access to Amazon ECR                                                                       | L1    |                |                                   |
| 5.1.3   | Minimize cluster access to read-only for Amazon ECR                                                      | L1    |                |                                   |
| 5.1.4   | Minimize Container Registries to only those approved                                                     | L2    |                |                                   |
| 5.2     | Identity and Access Management (IAM)                                                                     |       |                |                                   |
| 5.2.1   | Prefer using dedicated EKS Service Accounts                                                              | L1    |                |                                   |
| 5.3     | AWS EKS Key Management Service                                                                           |       |                |                                   |
| 5.3.1   | Ensure Kubernetes Secrets are encrypted using Customer Master Keys (CMKs) managed in AWS KMS             | L1    |                |                                   |
| 5.4     | Cluster Networking                                                                                       |       |                |                                   |
| 5.4.1   | Restrict Access to the Control Plane Endpoint                                                            | L1    |                |                                   |
| 5.4.2   | Ensure clusters are created with Private Endpoint Enabled and Public Access Disabled                     | L2    |                |                                   |
| 5.4.3   | Ensure clusters are created with Private Nodes                                                           | L1    |                |                                   |
| 5.4.4   | Ensure Network Policy is Enabled and set as appropriate                                                  | L1    |                |                                   |
| 5.4.5   | Encrypt traffic to HTTPS load balancers with TLS certificates                                            | L2    |                |                                   |
| 5.5     | Authentication and Authorization                                                                         |       |                |                                   |
| 5.5.1   | Manage Kubernetes RBAC users with AWS IAM Authenticator for Kubernetes                                   | L2    |                |                                   |
| 5.6     | Other Cluster Configurations                                                                             |       |                |                                   |
| 5.6.1   | Consider Fargate for running untrusted workloads                                                         | L1    | Active         | Set the `fargate_selector`        |
|---------|----------------------------------------------------------------------------------------------------------|-------|----------------|-----------------------------------|
