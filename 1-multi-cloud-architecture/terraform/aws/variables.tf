###############################################################################
# AWS Module Variables
###############################################################################

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for AWS VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the bastion host"
  type        = string
}

variable "aws_bgp_asn" {
  description = "BGP ASN for the AWS Virtual Private Gateway"
  type        = number
  default     = 64512
}

variable "gcp_subnet_cidr" {
  description = "GCP subnet CIDR - used for security group rules allowing cross-cloud traffic"
  type        = string
}
