output "project_id" {
  description = "The ID (name) of the CodeBuild project."
  value       = aws_codebuild_project.this.id
}

output "project_name" {
  description = "The name of the CodeBuild project."
  value       = aws_codebuild_project.this.name
}

output "project_arn" {
  description = "The ARN of the CodeBuild project. Referenced by CodePipeline build stages."
  value       = aws_codebuild_project.this.arn
}

output "role_id" {
  description = "The name of the auto-created IAM service role, or null when an external role ARN was supplied."
  value       = local.create_role ? aws_iam_role.codebuild[0].id : null
}

output "role_arn" {
  description = "The ARN of the service role used by the project (auto-created or caller-supplied)."
  value       = local.service_role_arn
}

output "log_group_name" {
  description = "The name of the CloudWatch log group receiving build logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "badge_url" {
  description = "The publicly accessible build badge URL for the project."
  value       = aws_codebuild_project.this.badge_url
}
