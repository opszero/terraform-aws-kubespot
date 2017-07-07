# auditkube

<img src="http://assets.opszero.com.s3.amazonaws.com/images/auditkube.png" width="200px" />

Secure Images to use with [Kubernetes
Kops](https://github.com/kubernetes/kops) to help create images which help
with PCI/HIPAA Compliance.

# Features

 - [X] Encrypted Root Volume
 - [X] [OSSEC](https://ossec.github.io/): File System Monitoring for Changes.
 - [ ] Build Public Image on All Regions
 - [X] Logging via LogDNA
 - [ ] 2FA Login

# Usage

This image is created using [Packer](https://www.packer.io/) so you will need
to install it. Once you are done edit [image.json](./image.json)

Update the `region`, `aws_access_key` and `aws_secret_key` with the
appropriate regions.

To actually build the image run the following:

```
packer build image.json
```

To use this image with `kops` you need to pass in the AMI name listed.

```
kops create cluster --image AMI-NAME
```

# Base Image

Base Image is created used the Stable Image here:

https://github.com/kubernetes/kops/tree/master/channels

# Brought To You By opsZero

<a href="https://www.opszero.com"><img src="http://assets.opszero.com.s3.amazonaws.com/images/opszero_11_29_2016.png" width="300px"/></a>

This project is brought to you by [opsZero](https://www.opszero.com) we
provide DevOps and Cloud Infrastructure as a Service for Startups. If you
need help with your infrastructure reach out.

# License

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
