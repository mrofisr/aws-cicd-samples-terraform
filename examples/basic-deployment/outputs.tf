output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer. Browse here to reach the application."
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "URL of the ECR repository the pipeline pushes images to and ECS pulls from."
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster running the service."
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "Name of the ECS service updated by the pipeline's deploy stage."
  value       = module.ecs.service_name
}

output "codepipeline_name" {
  description = "Name of the CodePipeline orchestrating build and deployment."
  value       = module.codepipeline.pipeline_name
}
