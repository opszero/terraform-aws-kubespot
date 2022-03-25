resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "metrics-server"
  namespace  = "kube-system"
  version    = var.metrics_server_version
  wait       = false
  values = [<<EOF
apiService:
  create: true
EOF
  ]
}
