# KubeSeed

AWS EKS Setup with some additional security to access the cluster.

- FoxPass
- Bastion

## Usage

```

resource "aws_eip" "cluster" {
  instance = "${aws_instance.web.id}"
  vpc      = true
}

module "opszero-eks" {
  source = "git::https://github.com/opszero/kubeseed.git"

  cluster-name = "cluster-eks"
  zones = ["us-west-2a", "us-west-2b"]
  eips = ["${aws_eip.cluster}]
  db_vpc_id = ""
  vpc_peer_name = ""
  ec2_keypair = ""
}
```

# Run

``` sh
aws iam create-service-linked-role --aws-service-name spot.amazonaws.com
```
