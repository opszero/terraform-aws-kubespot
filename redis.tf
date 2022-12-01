resource "aws_elasticache_subnet_group" "default" {
  name       = var.environment_name
  subnet_ids = concat(aws_subnet.private.*.id, aws_subnet.public.*.id)
}

resource "aws_elasticache_replication_group" "default" {
  automatic_failover_enabled = true
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  node_type                  = var.redis_node_type
  num_cache_clusters         = var.redis_num_nodes
  port                       = 6379
  parameter_group_name       = var.redis_parameter_gp_name
  subnet_group_name          = aws_elasticache_subnet_group.default.name
  description                = "A automatic_failover_enabled=true replication group that should also be multi-az"
  replication_group_id       = var.environment_name
  security_group_ids         = [aws_security_group.node.id]

  tags = {
    "KubespotEnvironment" = var.environment_name
  }

}

resource "null_resource" "nr" {
  triggers = {
    cache = aws_elasticache_replication_group.default.id
  }
  provisioner "local-exec" {
    command = "aws elasticache modify-replication-group --replication-group-id ${aws_elasticache_replication_group.default.id} --multi-az-enabled --apply-immediately"
  }
}
