# Kubespot (AWS)

<img src="http://assets.opszero.com.s3.amazonaws.com/images/auditkube.png" width="200px" />

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

karpenter.yml

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
