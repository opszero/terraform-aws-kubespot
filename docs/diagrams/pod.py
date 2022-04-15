#!/usr/bin/env python

from diagrams import Cluster, Diagram
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.compute import Deployment, Pod, ReplicaSet, Cronjob
from diagrams.k8s.network import Ingress, Service

with Diagram("EKS Nodes", show=True):
    with Cluster("EKS Nodes"):
        net = Ingress("cartx.io") >> Service("Nginx (ELB)") >> Deployment("Nginx Controller (HPA)")

        with Cluster("cartx-ecomm-ui (helm)"):
            net >> Service("cartx-ecomm-ui (ClusterIP)") >> [
                Deployment("cartx-ecomm-ui (HPA)"),
            ]
            Cronjob("cartx-ecomm-ui")

        with Cluster("cartx-ecomm (helm)"):
            net >> Service("cartx-ecomm (ClusterIP)") >> [
                Deployment("cartx-ecomm (HPA)"),
            ]
            Cronjob("cartx-ecomm")
