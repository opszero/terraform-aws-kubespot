# auditkube

Secure Images to use with [Kubernetes
Kops](https://github.com/kubernetes/kops) to help create images which help
with PCI/HIPAA Compliance.

# Features

 - [X] Encrypted Root Volume
 - [X] [OSSEC](https://ossec.github.io/): File System Monitoring for Changes.
 - [ ] Build Public Image on All Regions
 - [ ] Support Different Logging Mechanisms for the Image
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

# Brought To You By opsZero

![opsZero](https://s3-us-west-2.amazonaws.com/assets.opszero.com/images/opsZero_kubernetes.png)

This project is brought to you by [opsZero](https://www.opszero.com) we
provide DevOps and Cloud Infrastructure as a Service for Startups. If you
need help with your infrastructure reach out.

# License

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.