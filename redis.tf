resource "aws_elasticache_subnet_group" "default" {
  name       = var.environment_name
  subnet_ids = concat(aws_subnet.private.*.id, aws_subnet.public.*.id)
}

# resource "aws_elasticache_parameter_group" "default" {
#   name   = "cache-params"
#   family = "redis2.8"

#   parameter {
#     name  = "activerehashing"
#     value = "yes"
#   }

#   parameter {
#     name  = "min-slaves-to-write"
#     value = "2"
#   }
# }

resource "aws_elasticache_replication_group" "default" {
  count = var.redis_enabled ? 1 : 0

  replication_group_id       = var.environment_name
  description                = "redis cluster with autoscaling"
  node_type                  = "cache.r5.large"
  port                       = 6379
  parameter_group_name       = "default.redis6.x.cluster.on"
  automatic_failover_enabled = true
  engine                     = "redis"
  subnet_group_name          = aws_elasticache_subnet_group.default.name
  security_group_ids         = [aws_security_group.node.id]
  multi_az_enabled           = true


  num_node_groups         = 1
  replicas_per_node_group = 1
  tags                    = local.tags
}

resource "aws_appautoscaling_target" "redis" {
  count = var.redis_enabled ? 1 : 0

  service_namespace  = "elasticache"
  scalable_dimension = "elasticache:replication-group:Replicas"
  resource_id        = "replication-group/${aws_elasticache_replication_group.default[count.index].id}"
  min_capacity       = 1
  max_capacity       = 5
}

resource "aws_appautoscaling_policy" "redis" {
  count = var.redis_enabled ? 1 : 0

  name               = "cpu-auto-scaling"
  service_namespace  = aws_appautoscaling_target.redis[count.index].service_namespace
  scalable_dimension = aws_appautoscaling_target.redis[count.index].scalable_dimension
  resource_id        = aws_appautoscaling_target.redis[count.index].resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ElastiCacheReplicaEngineCPUUtilization"
    }

    target_value       = 70
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}