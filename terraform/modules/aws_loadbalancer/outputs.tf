output "alb_id" {
  description = "ID of the Application Load Balancer."
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Canonical hosted zone ID of the Application Load Balancer (for Route 53 alias records)."
  value       = aws_lb.this.zone_id
}

output "alb_security_group_id" {
  description = "ID of the security group attached to the load balancer."
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the target group."
  value       = aws_lb_target_group.this.arn
}

output "target_group_name" {
  description = "Name of the target group."
  value       = aws_lb_target_group.this.name
}

output "target_group_id" {
  description = "ID of the target group."
  value       = aws_lb_target_group.this.id
}

output "http_listener_arn" {
  description = "ARN of the HTTP (port 80) listener."
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS (port 443) listener, or null when SSL is not configured."
  value       = local.enable_https ? aws_lb_listener.https[0].arn : null
}

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate. Populated when create_acm_certificate is true, null otherwise."
  value       = var.create_acm_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : null
}

output "acm_certificate_domain" {
  description = "Primary domain name of the auto-created ACM certificate, or null when create_acm_certificate is false."
  value       = var.create_acm_certificate ? aws_acm_certificate.this[0].domain_name : null
}
