#!/usr/bin/env python3

#!/usr/bin/env python

from diagrams import Diagram
from diagrams.aws.compute import EC2, EKS
from diagrams.aws.database import RDS, Elasticache
from diagrams.aws.network import ELB, VPC

from diagrams import Cluster, Diagram
from diagrams.aws.compute import ECS, AutoScaling
from diagrams.aws.database import ElastiCache, RDS
from diagrams.aws.network import ELB
from diagrams.aws.network import Route53

with Diagram("Deployment", show=True):
    EC2("Bitbucket") >> EC2("Bamboo") >> EC2("Build Image") >> EC2("Push to ECR") >> EC2("Helm Chart") >> EC2("Add Secrets") >> EC2("Deploy to EKS Cluster")
