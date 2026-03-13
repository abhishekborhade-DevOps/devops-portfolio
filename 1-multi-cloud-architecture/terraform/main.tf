###############################################################################
# Root Module — Multi-Cloud Architecture: AWS <-> GCP Secure Connectivity
#
# Module call order:
#   1. aws_infra   → provisions AWS-side resources, outputs vpn_gateway_id
#   2. gcp_infra   → provisions GCP-side resources, outputs ha_vpn_ips
#   3. vpn_connectivity → wires up VPN tunnels + BGP using outputs from above
###############################################################################

###############################################################################
# AWS Infrastructure
# Provisions: VPC, Subnets, IGW, NAT GW, Route Tables, EC2, VPN Gateway
###############################################################################

module "aws_infra" {
  source = "./aws"

  project_name        = var.project_name
  environment         = var.environment
  aws_region          = var.aws_region
  vpc_cidr            = var.aws_vpc_cidr
  public_subnet_cidr  = var.aws_public_subnet_cidr
  private_subnet_cidr = var.aws_private_subnet_cidr
  instance_type       = var.aws_instance_type
  key_name            = var.aws_key_name
  allowed_ssh_cidr    = var.allowed_ssh_cidr
  aws_bgp_asn         = var.aws_bgp_asn
  gcp_subnet_cidr     = var.gcp_subnet_cidr
}

###############################################################################
# GCP Infrastructure
# Provisions: VPC, Subnet, Firewall, VM, Cloud Router, HA VPN Gateway
###############################################################################

module "gcp_infra" {
  source = "./gcp"

  project_name = var.project_name
  environment  = var.environment
  gcp_project  = var.gcp_project_id
  gcp_region   = var.gcp_region
  gcp_zone     = var.gcp_zone
  vpc_cidr     = var.gcp_vpc_cidr
  subnet_cidr  = var.gcp_subnet_cidr
  machine_type = var.gcp_machine_type
  gcp_bgp_asn  = var.gcp_bgp_asn
  aws_vpc_cidr = var.aws_vpc_cidr
}

###############################################################################
# VPN Connectivity
# Provisions: AWS Customer GWs, VPN Connections, GCP Tunnels, BGP Peers
###############################################################################

module "vpn_connectivity" {
  source = "./vpn"

  project_name = var.project_name
  environment  = var.environment

  # AWS side
  aws_region                 = var.aws_region
  aws_vpc_id                 = module.aws_infra.vpc_id
  aws_vpn_gateway_id         = module.aws_infra.vpn_gateway_id
  aws_private_route_table_id = module.aws_infra.private_route_table_id
  aws_bgp_asn                = var.aws_bgp_asn

  # GCP side
  gcp_project        = var.gcp_project_id
  gcp_region         = var.gcp_region
  gcp_network        = module.gcp_infra.network_self_link
  gcp_router_name    = module.gcp_infra.cloud_router_name
  gcp_ha_vpn_gateway = module.gcp_infra.ha_vpn_gateway_name
  gcp_ha_vpn_ip_0    = module.gcp_infra.ha_vpn_ip_0
  gcp_ha_vpn_ip_1    = module.gcp_infra.ha_vpn_ip_1
  gcp_bgp_asn        = var.gcp_bgp_asn

  # Network CIDRs
  aws_vpc_cidr    = var.aws_vpc_cidr
  gcp_subnet_cidr = var.gcp_subnet_cidr

  # VPN Pre-Shared Keys (sensitive)
  vpn_tunnel1_psk = var.vpn_tunnel1_psk
  vpn_tunnel2_psk = var.vpn_tunnel2_psk

  depends_on = [module.aws_infra, module.gcp_infra]
}
