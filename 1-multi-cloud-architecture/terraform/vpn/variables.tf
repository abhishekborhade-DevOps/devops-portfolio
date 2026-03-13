###############################################################################
# VPN Module Variables
###############################################################################

variable "project_name" {
  description = "Project name prefix for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

#------------------------------------------------------------------------------
# AWS Side
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_vpc_id" {
  description = "AWS VPC ID"
  type        = string
}

variable "aws_vpn_gateway_id" {
  description = "AWS Virtual Private Gateway ID (created in aws module)"
  type        = string
}

variable "aws_private_route_table_id" {
  description = "AWS private route table ID (for VPN route propagation verification)"
  type        = string
}

variable "aws_bgp_asn" {
  description = "AWS BGP ASN - used as peer ASN in GCP Cloud Router BGP peers"
  type        = number
}

#------------------------------------------------------------------------------
# GCP Side
#------------------------------------------------------------------------------

variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "gcp_network" {
  description = "GCP VPC network self link"
  type        = string
}

variable "gcp_router_name" {
  description = "GCP Cloud Router name (created in gcp module)"
  type        = string
}

variable "gcp_ha_vpn_gateway" {
  description = "GCP HA VPN Gateway name (created in gcp module)"
  type        = string
}

variable "gcp_ha_vpn_ip_0" {
  description = "GCP HA VPN Gateway interface 0 external IP"
  type        = string
}

variable "gcp_ha_vpn_ip_1" {
  description = "GCP HA VPN Gateway interface 1 external IP"
  type        = string
}

variable "gcp_bgp_asn" {
  description = "GCP BGP ASN - used as Customer Gateway BGP ASN in AWS"
  type        = number
}

#------------------------------------------------------------------------------
# Network CIDRs
#------------------------------------------------------------------------------

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR block"
  type        = string
}

variable "gcp_subnet_cidr" {
  description = "GCP subnet CIDR block"
  type        = string
}

#------------------------------------------------------------------------------
# VPN Secrets
#------------------------------------------------------------------------------

variable "vpn_tunnel1_psk" {
  description = "Pre-Shared Key for VPN tunnels 1 (Tunnel A and C)"
  type        = string
  sensitive   = true
}

variable "vpn_tunnel2_psk" {
  description = "Pre-Shared Key for VPN tunnels 2 (Tunnel B and D)"
  type        = string
  sensitive   = true
}
