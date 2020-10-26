#!/usr/bin/env ruby

# https://docs.aws.amazon.com/eks/latest/userguide/update-cluster.html

version = ARGV[0]

puts version

case version
when '1.13'
  puts `kubectl patch daemonset kube-proxy -n kube-system -p '{"spec": {"template": {"spec": {"containers": [{"image": "602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy:v1.13.7","name":"kube-proxy"}]}}}}'`
  puts `kubectl set image --namespace kube-system deployment.apps/coredns coredns=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns:v1.2.6`
when '1.18'
  puts `kubectl patch daemonset kube-proxy -n kube-system -p '{"spec": {"template": {"spec": {"containers": [{"image": "602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy:v1.18.8-eksbuild.1","name":"kube-proxy"}]}}}}'`
  puts `kubectl set image --namespace kube-system deployment.apps/coredns coredns=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns:v1.7.0-eksbuild.1`
  puts `kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/master/config/v1.7/aws-k8s-cni.yaml`
end
