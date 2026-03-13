###############################################################################
# GCP Module Variables
###############################################################################

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region for resource deployment"
  type        = string
}

variable "gcp_zone" {
  description = "GCP availability zone for VM instance"
  type        = string
}

variable "vpc_cidr" {
  description = "Informational VPC CIDR range (GCP uses subnet-level CIDRs)"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block for the GCP subnet"
  type        = string
}

variable "machine_type" {
  description = "GCP VM machine type"
  type        = string
  default     = "e2-micro"
}

variable "gcp_bgp_asn" {
  description = "BGP ASN for Cloud Router - must differ from AWS BGP ASN"
  type        = number
  default     = 65000
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR - used for firewall rules to allow cross-cloud traffic"
  type        = string
}
