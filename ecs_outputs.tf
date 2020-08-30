output "ecs_cluster_id" {
  description = "The ARN of the ECS cluster hosting Samproxy"
  value       = aws_ecs_cluster.cluster.arn
}
