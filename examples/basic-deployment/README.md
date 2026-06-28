# Basic Deployment Example

This directory contains a complete Terraform deployment example using the modules in this repository. It sets up a private VPC, ALB, ECR repository, ECS Fargate service, and a complete GitHub-triggered CodePipeline CI/CD pipeline.

> **Note**: Run all terraform commands from this directory (`examples/basic-deployment/`).

---

## Deploy Your First App

**Goal**: Get a working web app deployed to AWS in 30 minutes.

**Before you start**: You need Terraform installed, AWS CLI set up, and a GitHub repo.

### Step 1: Get the Code
```bash
git clone https://github.com/mrofisr/aws-cicd-samples-terraform
cd aws-cicd-samples-terraform/examples/basic-deployment
```

### Step 2: Configure Your Settings
1. Copy the example config: `cp terraform.tfvars.example terraform.tfvars`
2. Edit `terraform.tfvars` and change these values:
   ```hcl
   app_name   = "my-first-app"           # Your app name
   repo_owner = "your-github-username"   # Your GitHub username
   repo_name  = "your-app-repo"          # Your app's repo name
   ```

### Step 3: Connect GitHub to AWS
1. Run: `aws codestar-connections create-connection --provider-type GitHub --connection-name my-connection`
2. Open AWS Console → CodeStar Connections → Complete the GitHub authorization
3. Copy the connection ARN to `terraform.tfvars`

### Step 4: Deploy Everything
```bash
terraform init    # Download AWS provider and modules
terraform plan     # Preview what will be created
terraform apply    # Create everything (takes ~10 minutes)
```

### Step 5: Test Your App
1. Push code to your GitHub repo
2. Watch the pipeline run in AWS Console → CodePipeline  
3. Find your app URL in the terraform output: `alb_dns_name`
4. Visit `http://your-alb-url/health` - should return "ok"

**What just happened?** You created 20+ AWS resources that work together to run your web app with auto-deployment.

---

## How-To Guides

### Add HTTPS to Your App
1. Get an SSL certificate in AWS Certificate Manager
2. Add the certificate ARN to your `terraform.tfvars`:
   ```hcl
   ssl_certificate_arn = "arn:aws:acm:us-west-2:783764617931789012:certificate/78376461793178-1234-1234-1234-783764617931789012"
   ```
3. Run `terraform apply`

### Scale Your App Up or Down  
Change `desired_count` in `terraform.tfvars` and run `terraform apply`.

### Use a Custom Domain
1. Set up your domain in Route 53
2. Point your domain to the ALB DNS name from terraform output

### Clean Up Everything
```bash
terraform destroy  # Removes all AWS resources
```

---

## Reference

### Required Variables
| Name | Description | Example |
|------|-------------|---------|
| `codestar_connection_arn` | GitHub connection ARN | `arn:aws:codestar-connections:...` |
| `repo_owner` | GitHub username | `"myusername"` |
| `repo_name` | Repository name | `"my-web-app"` |

### Optional Variables  
| Name | Default | Description |
|------|---------|-------------|
| `container_port` | `8080` | Port your app listens on |
| `desired_count` | `1` | Number of app instances |
| `environment` | `"dev"` | Environment name |

### Outputs
| Name | Description |
|------|-------------|
| `alb_dns_name` | Your app's web address |
| `ecr_repository_url` | Where container images are stored |
| `ecs_cluster_name` | Container cluster name |

### App Requirements
Your app must:
- Listen on port 8080 (or set `container_port`)
- Respond to `/health` with HTTP 200 status
- Have a `Dockerfile` in the repo root
- Have a `buildspec.yml` for the build process (referenced by CodeBuild from the root or explicitly configured)
