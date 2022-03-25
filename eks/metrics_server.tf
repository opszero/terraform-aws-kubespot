resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "metrics-server"
  version    = var.metrics_server_version
  wait       = false
  values = [<<EOF
apiService:
  create: true
EOF
  ]
}
