output "cluster_id" {
  description = "The ID of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "The ARN of the ECS cluster."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "The name of the ECS cluster."
  value       = aws_ecs_cluster.this.name
}

output "service_id" {
  description = "The ID (ARN) of the ECS service."
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "The full ARN of the task definition, including the revision. Used by the CodePipeline deploy stage to register new revisions."
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "The family name of the task definition."
  value       = aws_ecs_task_definition.this.family
}

output "task_exec_role_arn" {
  description = "The ARN of the ECS task execution role used to pull images, write logs, and read secrets."
  value       = aws_iam_role.ecs_execution.arn
}

output "task_exec_role_name" {
  description = "The name of the ECS task execution role. Attach additional policies to this role when the workload needs more execution-time permissions."
  value       = aws_iam_role.ecs_execution.name
}

output "task_role_arn" {
  description = "The ARN of the ECS task role assumed by the running application container."
  value       = aws_iam_role.ecs_task.arn
}
