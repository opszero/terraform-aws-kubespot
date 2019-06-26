# AuditKube

<img src="http://assets.opszero.com.s3.amazonaws.com/images/auditkube.png" width="200px" />

Compliance Oriented Kubernetes for Amazon EKS. Setup machine images that are
compliance oriented for PCI/HIPAA/SOC2 and setup clusters using Terraform.

# Features

- [x] Encrypted Root Volume
- [x] [OSSEC](https://ossec.github.io/): File System Monitoring for Changes.
- [x] Logging via LogDNA
- [ ] Build Public Image on All Regions
- [ ] 2FA Login with Duo
- Third Party
  - LogDNA
  - Foxpass
  - Duo

# Usage

This image is created using [Packer](https://www.packer.io/) so you will need
to install it. Once you are done edit [image.json](./image.json)

Update the `region`, `aws_access_key` and `aws_secret_key` with the
appropriate regions.

To actually build the image run the following:

```
packer build image.json
```

> To use this image with `kops` you need to pass in the AMI name listed.

an example .auto.tfvars file is below 
```
foxpass_api_key = "<foxpass_api_key>"
cluster-name = "<name>"
ec2_keypair = "<keypair>"
```
in order to set up the bastion you need to download the private key 
and have it in the repository. 

### CloudWatch

You can pass the environment variables `CLOUDWATCH_AWS_ACCESS_KEY_ID`
and `CLOUDWATCH_AWS_SECRET_ACCESS_KEY` to push metrics into AWS
CloudWatch. To do so make sure that the key has permissions to the
following resources.

```
cloudwatch:PutMetricData
cloudwatch:GetMetricStatistics
cloudwatch:ListMetrics
ec2:DescribeTags
```

# Supported Images

- [AWS Marketplace](https://aws.amazon.com/marketplace/pp/B075CNX5F8?qid=1504900511561&sr=0-1&ref_=srh_res_product_title)

# Project by opsZero

<a href="https://www.opszero.com"><img src="http://assets.opszero.com.s3.amazonaws.com/images/opszero_11_29_2016.png" width="300px"/></a>

This project is brought to you by [opsZero](https://www.opszero.com) we
provide Kubernetes and AWS Lambda Migration. If you need help with your
Kubernetes Migration reach out.

# License

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
