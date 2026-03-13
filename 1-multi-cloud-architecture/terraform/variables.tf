###############################################################################
# Root Variables - Global Configuration
###############################################################################

#------------------------------------------------------------------------------
# General
#------------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project (used for resource naming and tagging)"
  type        = string
  default     = "multi-cloud-vpn"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner of the resources (for tagging and cost attribution)"
  type        = string
  default     = "devops-team"
}

#------------------------------------------------------------------------------
# AWS Configuration
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_vpc_cidr" {
  description = "CIDR block for AWS VPC. Must not overlap with GCP subnet CIDR."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.aws_vpc_cidr, 0))
    error_message = "aws_vpc_cidr must be a valid CIDR block."
  }
}

variable "aws_public_subnet_cidr" {
  description = "CIDR block for AWS public subnet (must be within aws_vpc_cidr)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "aws_private_subnet_cidr" {
  description = "CIDR block for AWS private subnet (must be within aws_vpc_cidr)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "aws_instance_type" {
  description = "EC2 instance type for test instances (bastion + private)"
  type        = string
  default     = "t3.micro"
}

variable "aws_key_name" {
  description = "AWS EC2 key pair name for SSH access. Must exist in the target region."
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed for SSH access to bastion host. Use YOUR_IP/32 for security."
  type        = string
  default     = "0.0.0.0/0"
}

variable "aws_bgp_asn" {
  description = "BGP ASN for AWS Virtual Private Gateway. Must not conflict with GCP BGP ASN."
  type        = number
  default     = 64512

  validation {
    condition     = var.aws_bgp_asn >= 64512 && var.aws_bgp_asn <= 65534
    error_message = "aws_bgp_asn must be in the private ASN range (64512-65534)."
  }
}

#------------------------------------------------------------------------------
# GCP Configuration
#------------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "GCP Project ID where resources will be deployed"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resource deployment"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP availability zone for VM instance"
  type        = string
  default     = "us-central1-a"
}

variable "gcp_vpc_cidr" {
  description = "Informational VPC CIDR range for GCP (GCP uses subnet-level CIDRs)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gcp_subnet_cidr" {
  description = "CIDR block for GCP subnet. Must not overlap with AWS VPC CIDR."
  type        = string
  default     = "10.1.1.0/24"

  validation {
    condition     = can(cidrhost(var.gcp_subnet_cidr, 0))
    error_message = "gcp_subnet_cidr must be a valid CIDR block."
  }
}

variable "gcp_machine_type" {
  description = "GCP VM machine type for test instance"
  type        = string
  default     = "e2-micro"
}

variable "gcp_bgp_asn" {
  description = "BGP ASN for GCP Cloud Router. Must not conflict with AWS BGP ASN."
  type        = number
  default     = 65000

  validation {
    condition     = var.gcp_bgp_asn >= 64512 && var.gcp_bgp_asn <= 65534
    error_message = "gcp_bgp_asn must be in the private ASN range (64512-65534)."
  }
}

#------------------------------------------------------------------------------
# VPN Configuration
#------------------------------------------------------------------------------

variable "vpn_tunnel1_psk" {
  description = "Pre-Shared Key for VPN Tunnel 1. Use a strong, random value (min 8 chars)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.vpn_tunnel1_psk) >= 8
    error_message = "VPN PSK must be at least 8 characters long."
  }
}

variable "vpn_tunnel2_psk" {
  description = "Pre-Shared Key for VPN Tunnel 2. Use a strong, random value (min 8 chars)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.vpn_tunnel2_psk) >= 8
    error_message = "VPN PSK must be at least 8 characters long."
  }
}
