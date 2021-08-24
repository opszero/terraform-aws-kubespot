# Kubespot

<img src="http://assets.opszero.com.s3.amazonaws.com/images/auditkube.png" width="200px" />

Compliance Oriented Kubernetes Setup for Amazon, Google and Azure.

AuditKube is an open source terraform module that attempts to create a
complete compliance-oriented Kubernetes setup on AWS, Google Cloud and Azure.
These add additional security such as additional system logs, file system
monitoring, hard disk encryption and access control. Further, we setup the
managed Redis and SQL on each of the Cloud providers with limited access to
the Kubernetes cluster so things are further locked down. All of this should
lead to setting up a HIPAA / PCI / SOC2 being made straightforward and
repeatable.

 - [Documentation](https://www.notion.so/opszero/Kubernetes-f126f92e477c4a0c90f3a0ec7262bcf1)

# Third-Party Addons

- [OSSEC](https://ossec.github.io/): File System Monitoring for Changes.
- Logging via LogDNA
- Third Party
  - LogDNA
  - Foxpass

<a href="https://www.opszero.com"><img src="http://assets.opszero.com.s3.amazonaws.com/images/opszero_11_29_2016.png" width="300px"/></a>

This project is by [opsZero](https://www.opszero.com). We help organizations
migrate to Kubernetes so [reach out](https://www.opszero.com/#contact) if you
need help!

# License

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
