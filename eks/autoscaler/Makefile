AWS_ACCOUNT=<ACCOUNT>
KUBECONFIG=<kubeconfig>
CLUSTER_NAME=<cluster_name>

# https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
autoscaler-%:
        KUBECONFIG=$(KUBECONFIG) kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.1/components.yaml
        cat cluster-autoscaler-autodiscover.yaml | sed -e 's/OPSZERO_CLUSTER_NAME/$(CLUSTER_NAME)/g' > autoscaler.yaml
        KUBECONFIG=$(KUBECONFIG) kubectl apply -f autoscaler.yaml
        -KUBECONFIG=$(KUBECONFIG) kubectl annotate serviceaccount cluster-autoscaler -n kube-system --overwrite eks.amazonaws.com/role-arn=arn:aws:iam::$(AWS_ACCOUNT):role/$(CLUSTER_NAME)-$*-node-oidc
        KUBECONFIG=$(KUBECONFIG) kubectl patch deployment cluster-autoscaler -n kube-system -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'
        KUBECONFIG=$(KUBECONFIG) kubectl set image deployment cluster-autoscaler -n kube-system cluster-autoscaler=k8s.gcr.io/autoscaling/cluster-autoscaler:v1.18.3
