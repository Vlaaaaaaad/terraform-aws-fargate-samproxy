output "samproxy_url" {
  description = "The URL to use for Samproxy"
  value       = local.samproxy_url
}

output "samproxy_execution_role_arn" {
  description = "The IAM Role used to create the Samproxy tasks"
  value       = aws_ecs_task_definition.samproxy.execution_role_arn
}

output "samproxy_task_role_arn" {
  description = "The Atlantis ECS task role name"
  value       = aws_ecs_task_definition.samproxy.task_role_arn
}

output "samproxy_ecs_task_definition" {
  description = "The task definition for the Samproxy ECS service"
  value       = aws_ecs_service.samproxy.task_definition
}

output "samproxy_ecs_security_group" {
  description = "The ID of the Security group assigned to the Samproxy ECS Service"
  value       = aws_security_group.samproxy.id
}
