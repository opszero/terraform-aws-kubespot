resource "helm_release" "datadog" {
  name       = "datadog"
  repository = "https://helm.datadoghq.com"
  chart      = "datadog"

  namespace        = "datadog"
  create_namespace = true

  # Default Configuration items
  set {
    name  = "datadog.apiKey"
    value = var.datadog_api_key
  }

  set {
    name  = "clusterAgent.enabled"
    value = true
  }

  set {
    name  = "targetSystem"
    value = "linux"
  }

  # Set Datadog Configuration Items

  # Event Collection
  set {
    name  = "agents.rbac.create"
    value = true
  }

  set {
    name  = "datadog.leaderElection"
    value = true
  }

  set {
    name  = "datadog.collectEvents"
    value = true
  }

  # Custom/External Metrics
  set {
    name  = "clusterAgent.metricsProvider.enabled"
    value = true
  }

  # APM Configuration
  set {
    name  = "datadog.apm.enabled"
    value = true
  }

  # Logs Configuration
  set {
    name  = "datadog.logs.enabled"
    value = true
  }

  set {
    name  = "datadog.logs.containerCollectAll"
    value = true
  }


  # Set logging verbosity, valid log levels are: trace, debug, info, warn, error, critical, off.  Default is info
  set {
    name  = "datadog.logLevel"
    value = "INFO"
  }

  # Process Collection Configuration
  set {
    name  = "datadog.processAgent.enabled"
    value = true
  }


}
