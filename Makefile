.PHONY: help init plan apply destroy fmt validate clean

ENVIRONMENT ?= dev
SHARED_VARS = environments/shared.tfvars
ENV_VARS = environments/$(ENVIRONMENT)/dhg-rateauto-$(ENVIRONMENT)-vpc.tfvars
BACKEND_VARS = environments/$(ENVIRONMENT)/dhg-rateauto-$(ENVIRONMENT)-vpc.backend.tfvars

help:
	@echo "DHG RateAuto VPC Terraform Makefile"
	@echo "===================================="
	@echo ""
	@echo "Usage: make [target] ENVIRONMENT=dev|stage|test"
	@echo ""
	@echo "Targets:"
	@echo "  init          - Initialize Terraform for the specified environment"
	@echo "  plan          - Generate and show execution plan"
	@echo "  apply         - Apply the Terraform configuration"
	@echo "  destroy       - Destroy all resources"
	@echo "  fmt           - Format Terraform files"
	@echo "  validate      - Validate Terraform configuration"
	@echo "  clean         - Clean Terraform cache and lock files"
	@echo "  show-state    - Show current Terraform state"
	@echo "  output        - Show Terraform outputs"
	@echo ""
	@echo "Examples:"
	@echo "  make init ENVIRONMENT=dev"
	@echo "  make plan ENVIRONMENT=dev"
	@echo "  make apply ENVIRONMENT=stage"
	@echo "  make destroy ENVIRONMENT=test"
	@echo ""

init:
	@echo "Initializing Terraform for $(ENVIRONMENT) environment..."
	terraform init -backend-config="$(BACKEND_VARS)"

plan: init
	@echo "Planning Terraform for $(ENVIRONMENT) environment..."
	terraform plan \
		-var-file="$(SHARED_VARS)" \
		-var-file="$(ENV_VARS)" \
		-out=tfplan-$(ENVIRONMENT)

apply: plan
	@echo "Applying Terraform for $(ENVIRONMENT) environment..."
	terraform apply tfplan-$(ENVIRONMENT)
	@rm -f tfplan-$(ENVIRONMENT)

destroy:
	@echo "WARNING: This will destroy all resources in $(ENVIRONMENT) environment!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read dummy
	terraform destroy \
		-var-file="$(SHARED_VARS)" \
		-var-file="$(ENV_VARS)"

fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

validate:
	@echo "Validating Terraform configuration..."
	terraform validate

clean:
	@echo "Cleaning Terraform cache..."
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f tfplan-*
	@echo "Cleanup complete!"

show-state:
	@echo "Current Terraform state for $(ENVIRONMENT):"
	terraform show

output:
	@echo "Terraform outputs for $(ENVIRONMENT):"
	terraform output

plan-json: init
	@echo "Generating JSON plan for $(ENVIRONMENT) environment..."
	terraform plan \
		-var-file="$(SHARED_VARS)" \
		-var-file="$(ENV_VARS)" \
		-json > tfplan-$(ENVIRONMENT).json

# Dry-run without actually applying
dry-run: init
	@echo "Dry-run plan for $(ENVIRONMENT) environment..."
	terraform plan \
		-var-file="$(SHARED_VARS)" \
		-var-file="$(ENV_VARS)" \
		-no-color

# Deploy all environments
deploy-all:
	@echo "Deploying to Dev..."
	make apply ENVIRONMENT=dev
	@echo "Deploying to Stage..."
	make apply ENVIRONMENT=stage
	@echo "Deploying to Test..."
	make apply ENVIRONMENT=test

# Destroy all environments
destroy-all:
	@echo "WARNING: This will destroy all environments!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read dummy
	make destroy ENVIRONMENT=dev
	make destroy ENVIRONMENT=stage
	make destroy ENVIRONMENT=test
