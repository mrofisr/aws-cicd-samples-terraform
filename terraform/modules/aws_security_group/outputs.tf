output "security_group_id" {
  description = "The ID of the security group."
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "The ARN of the security group."
  value       = aws_security_group.this.arn
}

output "owner_id" {
  description = "The AWS account ID that owns the security group."
  value       = aws_security_group.this.owner_id
}

output "vpc_id" {
  description = "The VPC ID associated with the security group."
  value       = aws_security_group.this.vpc_id
}
