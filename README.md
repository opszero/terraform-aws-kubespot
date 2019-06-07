# KubeSeed

AWS EKS Setup with some additional security to access the cluster.

- FoxPass
- Bastion

### Inputs

- **cluster-name** - The name that the cluster should be called
- **zones** - (Default: [us-west-2a, us-west-2b]) The AZs the cluster should
  live in
- **eips** - The elastic IP addresses the master nodes should connect to
- **db_vpc_id** - The VPC ID where the databases live
- **vpc_peer_name** - (Default: eks-to-dbs) - What to name the peering
