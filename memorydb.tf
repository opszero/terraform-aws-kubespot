resource "aws_memorydb_subnet_group" "default" {
  name       = var.environment_name
  subnet_ids = aws_subnet.private.*.id
}

resource "aws_memorydb_cluster" "example" {
  count = var.memorydb_enabled ? 1 : 0

  acl_name                 = "open-access"
  name                     = var.environment_name
  node_type                = "db.t4g.small"
  num_shards               = 2
  num_replicas_per_shard   = 1
  parameter_group_name     = "default.memorydb-redis6"
  security_group_ids       = [aws_security_group.node.id]
  snapshot_retention_limit = 7
  subnet_group_name        = aws_memorydb_subnet_group.default.id
  tags                     = local.tags
}
