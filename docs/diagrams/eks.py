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

with Diagram("EKS Cluster", show=True):
    dns = Route53("Cloudflare DNS")

    with Cluster("VPC"):
        with Cluster("Public Subnet"):
            lb = ELB("ELB")

        with Cluster("Private Subnet"):
            with Cluster("Autoscaling (Vertical Autoscaler)"):
                svc_group = [EC2("node1"),
                             EC2("node2"),
                             EC2("node3")]

        with Cluster("RDS"):
            db_master = RDS("Leader")
            db_master - [RDS("Follower")]

        redis = ElastiCache("Redis")

    dns >> lb >> svc_group
    svc_group >> db_master
    svc_group >> redis
