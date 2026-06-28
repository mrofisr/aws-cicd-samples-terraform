# AWS CI/CD Infrastructure with Terraform

Deploy a containerized web application on AWS with an automated CI/CD pipeline using Terraform modules.

This repository provides reusable infrastructure components structured as Terraform modules, along with a basic example deployment.

## Terraform Modules Catalog

The modules in this repository are located under `terraform/modules/` and can be used independently:

- **[aws_vpc](terraform/modules/aws_vpc/README.md)**: Configures a secure Virtual Private Cloud (VPC) with public and private subnets, routing tables, and an optional NAT Gateway.
- **[aws_security_group](terraform/modules/aws_security_group/README.md)**: Creates security groups with configurable ingress/egress rules.
- **[aws_ecr](terraform/modules/aws_ecr/README.md)**: Sets up an Amazon Elastic Container Registry (ECR) repository with lifecycle policies and image scanning.
- **[aws_ecs](terraform/modules/aws_ecs/README.md)**: Deploys an Amazon Elastic Container Service (ECS) Fargate cluster, service, and task definitions.
- **[aws_loadbalancer](terraform/modules/aws_loadbalancer/README.md)**: Creates an Application Load Balancer (ALB) with listener rules and target groups.
- **[aws_codebuild](terraform/modules/aws_codebuild/README.md)**: Sets up an AWS CodeBuild project to build container images.
- **[aws_codepipeline](terraform/modules/aws_codepipeline/README.md)**: Deploys an AWS CodePipeline to orchestrate the CI/CD pipeline from GitHub to ECS Fargate.

## Getting Started

To deploy a sample pipeline using these modules:

1. Navigate to the deployment example directory:
   ```bash
   cd examples/basic-deployment
   ```
2. Follow the deployment instructions in the **[Deployment Example Tutorial](examples/basic-deployment/README.md)**.
