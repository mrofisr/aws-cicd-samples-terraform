.PHONY: help init plan apply destroy validate fmt lint tfsec lock output build run clean encrypt decrypt
.DEFAULT_GOAL := help

# Configuration
TF_DIR := examples/basic-deployment
AWS_REGION ?= us-east-1
TF_WORKSPACE ?= default
TF_VARS_FILE ?= terraform.tfvars
ENCRYPT_FILE ?= $(TF_DIR)/$(TF_VARS_FILE)

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(CYAN)AWS CICD Terraform Sample - Makefile$(NC)"
	@echo ""
	@echo "$(GREEN)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Variables:$(NC)"
	@echo "  AWS_REGION     = $(AWS_REGION)"
	@echo "  TF_WORKSPACE   = $(TF_WORKSPACE)"
	@echo "  TF_VARS_FILE   = $(TF_VARS_FILE)"

init: ## Initialize Terraform (download providers and modules)
	@echo "$(GREEN)Initializing Terraform...$(NC)"
	cd $(TF_DIR) && terraform init

plan: ## Show Terraform execution plan
	@echo "$(GREEN)Running Terraform plan...$(NC)"
	cd $(TF_DIR) && terraform plan -var-file=$(TF_VARS_FILE)

apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes...$(NC)"
	cd $(TF_DIR) && terraform apply -var-file=$(TF_VARS_FILE)

destroy: ## Destroy all Terraform-managed infrastructure
	@echo "$(RED)Destroying infrastructure...$(NC)"
	cd $(TF_DIR) && terraform destroy -var-file=$(TF_VARS_FILE)

validate: ## Validate Terraform configuration
	@echo "$(GREEN)Validating Terraform configuration...$(NC)"
	cd $(TF_DIR) && terraform validate

fmt: ## Format all Terraform files
	@echo "$(GREEN)Formatting Terraform files...$(NC)"
	terraform fmt -recursive

lint: ## Lint Terraform files with tflint (if available)
	@echo "$(GREEN)Linting Terraform files...$(NC)"
	@if command -v tflint > /dev/null; then \
		cd $(TF_DIR) && tflint; \
	else \
		echo "$(YELLOW)tflint not installed. Skipping lint check.$(NC)"; \
		echo "Install: https://github.com/terraform-linters/tflint"; \
	fi

tfsec: ## Run security scanning with tfsec (if available)
	@echo "$(GREEN)Running security scan...$(NC)"
	@if command -v tfsec > /dev/null; then \
		tfsec .; \
	else \
		echo "$(YELLOW)tfsec not installed. Skipping security scan.$(NC)"; \
		echo "Install: https://github.com/aquasecurity/tfsec"; \
	fi

lock: ## Update provider lock file
	@echo "$(GREEN)Updating provider lock file...$(NC)"
	cd $(TF_DIR) && terraform providers lock \
		-platform=linux_amd64 \
		-platform=linux_arm64 \
		-platform=darwin_amd64 \
		-platform=darwin_arm64 \
		-platform=windows_amd64

output: ## Show Terraform outputs
	@echo "$(GREEN)Terraform outputs:$(NC)"
	cd $(TF_DIR) && terraform output

build: ## Build Docker image locally
	@echo "$(GREEN)Building Docker image...$(NC)"
	docker build -t aws-cicd-sample:local ./apps

run: build ## Run Docker container locally on port 8080
	@echo "$(GREEN)Running container on http://localhost:8080$(NC)"
	docker run --rm -p 8080:8080 aws-cicd-sample:local

clean: ## Clean Terraform workspace
	@echo "$(YELLOW)Cleaning Terraform workspace...$(NC)"
	rm -rf $(TF_DIR)/.terraform
	rm -f $(TF_DIR)/.terraform.lock.hcl
	rm -f $(TF_DIR)/*.tfstate*
	rm -f $(TF_DIR)/*.plan
	@echo "$(GREEN)Clean complete.$(NC)"

workspace-list: ## List Terraform workspaces
	@echo "$(GREEN)Terraform workspaces:$(NC)"
	cd $(TF_DIR) && terraform workspace list

workspace-new: ## Create new Terraform workspace (usage: make workspace-new WORKSPACE=dev)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)Error: WORKSPACE variable required$(NC)"; \
		echo "Usage: make workspace-new WORKSPACE=dev"; \
		exit 1; \
	fi
	@echo "$(GREEN)Creating workspace: $(WORKSPACE)$(NC)"
	cd $(TF_DIR) && terraform workspace new $(WORKSPACE)

workspace-select: ## Select Terraform workspace (usage: make workspace-select WORKSPACE=dev)
	@if [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)Error: WORKSPACE variable required$(NC)"; \
		echo "Usage: make workspace-select WORKSPACE=dev"; \
		exit 1; \
	fi
	@echo "$(GREEN)Selecting workspace: $(WORKSPACE)$(NC)"
	cd $(TF_DIR) && terraform workspace select $(WORKSPACE)

encrypt: ## Encrypt a file with age using a passphrase (usage: make encrypt FILE=path/to/file)
	@if ! command -v age > /dev/null; then \
		echo "$(RED)Error: age is not installed.$(NC)"; \
		echo "Install: https://github.com/FiloSottile/age"; \
		exit 1; \
	fi
	@target="$(if $(FILE),$(FILE),$(ENCRYPT_FILE))"; \
	if [ ! -f "$$target" ]; then \
		echo "$(RED)Error: file not found: $$target$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)Encrypting $$target -> $$target.age$(NC)"; \
	age -p -o "$$target.age" "$$target"; \
	echo "$(GREEN)Done. You can now safely remove $$target if it should not be committed.$(NC)"

decrypt: ## Decrypt a file with age using a passphrase (usage: make decrypt FILE=path/to/file.age)
	@if ! command -v age > /dev/null; then \
		echo "$(RED)Error: age is not installed.$(NC)"; \
		echo "Install: https://github.com/FiloSottile/age"; \
		exit 1; \
	fi; \
	src="$(if $(FILE),$(FILE),$(ENCRYPT_FILE).age)"; \
	if [ ! -f "$$src" ]; then \
		echo "$(RED)Error: file not found: $$src$(NC)"; \
		exit 1; \
	fi; \
	dest="$${src%.age}"; \
	echo "$(GREEN)Decrypting $$src -> $$dest$(NC)"; \
	age -d -o "$$dest" "$$src"; \
	echo "$(GREEN)Done.$(NC)"
