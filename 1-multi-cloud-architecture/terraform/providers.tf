###############################################################################
# Provider Configuration
###############################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = var.owner
      Repository  = "devops-portfolio/multi-cloud-architecture"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}
