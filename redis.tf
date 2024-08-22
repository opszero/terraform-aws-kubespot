resource "aws_elasticache_subnet_group" "default" {
  count = var.redis_enabled ? 1 : 0

  name       = var.environment_name
  subnet_ids = concat(aws_subnet.private.*.id, aws_subnet.public.*.id)
}

resource "aws_elasticache_cluster" "default" {
  count      = var.redis_enabled ? 1 : 0
  cluster_id = var.environment_name

  engine    = "redis"
  node_type = var.redis_node_type

  num_cache_nodes = var.redis_num_nodes
  engine_version  = var.redis_engine_version
  port            = 6379

  subnet_group_name  = aws_elasticache_subnet_group.default.name
  security_group_ids = [aws_security_group.node.id]

  tags = {
    "KubespotEnvironment" = var.environment_name
  }
}
