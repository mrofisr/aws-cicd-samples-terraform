output "pipeline_id" {
  description = "The ID of the CodePipeline."
  value       = aws_codepipeline.this.id
}

output "pipeline_name" {
  description = "The name of the CodePipeline."
  value       = aws_codepipeline.this.name
}

output "pipeline_arn" {
  description = "The ARN of the CodePipeline."
  value       = aws_codepipeline.this.arn
}

output "role_arn" {
  description = "The ARN of the IAM role assumed by the pipeline."
  value       = aws_iam_role.this.arn
}

output "role_id" {
  description = "The ID (name) of the IAM role assumed by the pipeline."
  value       = aws_iam_role.this.id
}

output "artifact_bucket_id" {
  description = "The ID (name) of the S3 bucket used as the artifact store."
  value       = aws_s3_bucket.this.id
}

output "artifact_bucket_arn" {
  description = "The ARN of the S3 bucket used as the artifact store."
  value       = aws_s3_bucket.this.arn
}
