locals {
  tags = merge(var.tags, {
    "KubespotEnvironment" = var.environment_name
  })
}