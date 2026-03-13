##############################################################################
# Multi-Cloud Architecture — Developer Makefile
# Usage: make <target>
##############################################################################

TF_DIR   := 1-multi-cloud-architecture/terraform
TFVARS   := $(TF_DIR)/terraform.tfvars

.DEFAULT_GOAL := help

.PHONY: help init plan apply destroy fmt fmt-check validate lint \
        security-scan docs clean check-tools

# ── Help ─────────────────────────────────────────────────────────────────────

help: ## Show this help message
	@echo ''
	@echo '  Multi-Cloud Architecture — Available Commands'
	@echo ''
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ \
	  { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ''

# ── Terraform Lifecycle ───────────────────────────────────────────────────────

init: check-tools ## Initialize Terraform (download providers & modules)
	@echo "==> Initializing Terraform..."
	terraform -chdir=$(TF_DIR) init -upgrade

plan: check-tools ## Preview infrastructure changes
	@echo "==> Running Terraform plan..."
	terraform -chdir=$(TF_DIR) plan -out=tfplan

apply: check-tools ## Apply infrastructure changes (requires prior plan)
	@echo "==> Applying Terraform changes..."
	terraform -chdir=$(TF_DIR) apply tfplan

apply-auto: check-tools ## Apply without interactive approval (CI use)
	@echo "==> Applying Terraform changes (auto-approve)..."
	terraform -chdir=$(TF_DIR) apply -auto-approve

destroy: check-tools ## DESTROY all provisioned infrastructure
	@echo "==> WARNING: This will DESTROY all resources."
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ]
	terraform -chdir=$(TF_DIR) destroy

# ── Code Quality ─────────────────────────────────────────────────────────────

fmt: ## Auto-format all Terraform files
	@echo "==> Formatting Terraform files..."
	terraform -chdir=$(TF_DIR) fmt -recursive

fmt-check: ## Check formatting without modifying files (CI use)
	@echo "==> Checking Terraform formatting..."
	terraform -chdir=$(TF_DIR) fmt -recursive -check -diff

validate: init ## Validate Terraform configuration
	@echo "==> Validating Terraform configuration..."
	terraform -chdir=$(TF_DIR) validate

lint: ## Run tflint for Terraform linting (requires tflint installed)
	@which tflint > /dev/null || (echo "Install tflint: https://github.com/terraform-linters/tflint" && exit 1)
	@echo "==> Running tflint..."
	tflint --chdir=$(TF_DIR) --recursive

security-scan: ## Run tfsec security scanner (requires tfsec installed)
	@which tfsec > /dev/null || (echo "Install tfsec: brew install tfsec" && exit 1)
	@echo "==> Running tfsec security scan..."
	tfsec $(TF_DIR)

checkov: ## Run Checkov IaC security scan (requires checkov installed)
	@which checkov > /dev/null || (echo "Install: pip install checkov" && exit 1)
	@echo "==> Running Checkov scan..."
	checkov -d $(TF_DIR) --framework terraform

# ── Documentation ────────────────────────────────────────────────────────────

docs: ## Generate Terraform module documentation (requires terraform-docs)
	@which terraform-docs > /dev/null || (echo "Install: https://terraform-docs.io" && exit 1)
	@echo "==> Generating module documentation..."
	terraform-docs markdown table --output-file README.md $(TF_DIR)/aws
	terraform-docs markdown table --output-file README.md $(TF_DIR)/gcp
	terraform-docs markdown table --output-file README.md $(TF_DIR)/vpn

# ── Outputs & Status ─────────────────────────────────────────────────────────

output: ## Show Terraform outputs
	terraform -chdir=$(TF_DIR) output

show-ips: ## Show key IPs for connectivity testing
	@echo ""
	@echo "==> Key Infrastructure IPs"
	@echo "----------------------------------------------------"
	@terraform -chdir=$(TF_DIR) output aws_bastion_public_ip    2>/dev/null || true
	@terraform -chdir=$(TF_DIR) output aws_private_instance_ip  2>/dev/null || true
	@terraform -chdir=$(TF_DIR) output gcp_test_vm_internal_ip  2>/dev/null || true
	@echo ""

vpn-status: ## Check AWS VPN tunnel status
	@echo "==> AWS VPN Tunnel Status"
	@CONN0=$$(terraform -chdir=$(TF_DIR) output -raw aws_vpn_connection_0_id 2>/dev/null) && \
	 CONN1=$$(terraform -chdir=$(TF_DIR) output -raw aws_vpn_connection_1_id 2>/dev/null) && \
	 aws ec2 describe-vpn-connections \
	   --vpn-connection-ids $$CONN0 $$CONN1 \
	   --query 'VpnConnections[*].VgwTelemetry[*].{IP:OutsideIpAddress,Status:Status,Last:LastStatusChange}' \
	   --output table

# ── Utilities ────────────────────────────────────────────────────────────────

clean: ## Remove Terraform local state files and plan artifacts
	@echo "==> Cleaning Terraform artifacts..."
	rm -rf $(TF_DIR)/.terraform \
	       $(TF_DIR)/tfplan \
	       $(TF_DIR)/.terraform.lock.hcl \
	       $(TF_DIR)/crash.log

check-tools: ## Verify required CLI tools are installed
	@echo "==> Checking required tools..."
	@which terraform > /dev/null || (echo "ERROR: terraform not found. Install: https://terraform.io" && exit 1)
	@which aws > /dev/null       || (echo "ERROR: aws-cli not found. Install: https://aws.amazon.com/cli/" && exit 1)
	@which gcloud > /dev/null    || (echo "ERROR: gcloud not found. Install: https://cloud.google.com/sdk" && exit 1)
	@echo "  All required tools found."
