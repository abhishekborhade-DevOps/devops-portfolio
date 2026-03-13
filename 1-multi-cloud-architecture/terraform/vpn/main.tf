###############################################################################
# VPN Connectivity Module
#
# Implements full HA VPN between AWS and GCP using BGP dynamic routing.
#
# Architecture (4-tunnel FOUR_IPS_REDUNDANCY):
#
#   AWS VGW ──────── AWS CGW-0 ──────── GCP HA VPN (IF 0)
#                   (2 tunnels)              │
#                  tunnel_0                  │
#                  tunnel1 ─────────────> AWS Ext. GW IF 0
#                  tunnel2 ─────────────> AWS Ext. GW IF 1
#
#   AWS VGW ──────── AWS CGW-1 ──────── GCP HA VPN (IF 1)
#                   (2 tunnels)              │
#                  tunnel_1                  │
#                  tunnel1 ─────────────> AWS Ext. GW IF 2
#                  tunnel2 ─────────────> AWS Ext. GW IF 3
#
# BGP Inside CIDRs (link-local 169.254.x.x/30):
#   Tunnel A: 169.254.10.0/30
#   Tunnel B: 169.254.11.0/30
#   Tunnel C: 169.254.12.0/30
#   Tunnel D: 169.254.13.0/30
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

###############################################################################
# AWS SIDE - Customer Gateways
# Each CGW points to one GCP HA VPN external IP
###############################################################################

# Customer Gateway 1 - points to GCP HA VPN Interface 0
resource "aws_customer_gateway" "gcp_if0" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = var.gcp_ha_vpn_ip_0
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-cgw-gcp-if0"
  }
}

# Customer Gateway 2 - points to GCP HA VPN Interface 1
resource "aws_customer_gateway" "gcp_if1" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = var.gcp_ha_vpn_ip_1
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-cgw-gcp-if1"
  }
}

###############################################################################
# AWS SIDE - VPN Connections (each generates 2 tunnel IPs)
###############################################################################

# VPN Connection 0: AWS VGW <-> GCP HA VPN Interface 0
resource "aws_vpn_connection" "conn_0" {
  vpn_gateway_id      = var.aws_vpn_gateway_id
  customer_gateway_id = aws_customer_gateway.gcp_if0.id
  type                = "ipsec.1"
  static_routes_only  = false # Use BGP dynamic routing

  tunnel1_preshared_key = var.vpn_tunnel1_psk
  tunnel2_preshared_key = var.vpn_tunnel2_psk

  # Explicit BGP inside CIDRs (link-local range)
  tunnel1_inside_cidr = "169.254.10.0/30"
  tunnel2_inside_cidr = "169.254.11.0/30"

  tags = {
    Name = "${local.name_prefix}-vpn-conn-0"
  }
}

# VPN Connection 1: AWS VGW <-> GCP HA VPN Interface 1
resource "aws_vpn_connection" "conn_1" {
  vpn_gateway_id      = var.aws_vpn_gateway_id
  customer_gateway_id = aws_customer_gateway.gcp_if1.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_preshared_key = var.vpn_tunnel1_psk
  tunnel2_preshared_key = var.vpn_tunnel2_psk

  tunnel1_inside_cidr = "169.254.12.0/30"
  tunnel2_inside_cidr = "169.254.13.0/30"

  tags = {
    Name = "${local.name_prefix}-vpn-conn-1"
  }
}

###############################################################################
# GCP SIDE - External VPN Gateway (represents the AWS side)
# Uses FOUR_IPS_REDUNDANCY: all 4 AWS tunnel endpoint IPs
###############################################################################

resource "google_compute_external_vpn_gateway" "aws" {
  name            = "${local.name_prefix}-ext-vpn-aws"
  project         = var.gcp_project
  redundancy_type = "FOUR_IPS_REDUNDANCY"
  description     = "Represents AWS VPN endpoints (4 tunnel IPs for full HA)"

  # Interface 0 = AWS Connection 0, Tunnel 1
  interface {
    id         = 0
    ip_address = aws_vpn_connection.conn_0.tunnel1_address
  }

  # Interface 1 = AWS Connection 0, Tunnel 2
  interface {
    id         = 1
    ip_address = aws_vpn_connection.conn_0.tunnel2_address
  }

  # Interface 2 = AWS Connection 1, Tunnel 1
  interface {
    id         = 2
    ip_address = aws_vpn_connection.conn_1.tunnel1_address
  }

  # Interface 3 = AWS Connection 1, Tunnel 2
  interface {
    id         = 3
    ip_address = aws_vpn_connection.conn_1.tunnel2_address
  }
}

###############################################################################
# GCP SIDE - VPN Tunnels (4 tunnels for full HA)
###############################################################################

# Tunnel A: GCP Interface 0 <-> AWS Conn-0 Tunnel 1
resource "google_compute_vpn_tunnel" "tunnel_a" {
  name                            = "${local.name_prefix}-vpn-tunnel-a"
  project                         = var.gcp_project
  region                          = var.gcp_region
  vpn_gateway                     = var.gcp_ha_vpn_gateway
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 0
  shared_secret                   = var.vpn_tunnel1_psk
  router                          = var.gcp_router_name
  ike_version                     = 2
  description                     = "Tunnel A: GCP IF0 -> AWS Conn0 Tunnel1"
}

# Tunnel B: GCP Interface 0 <-> AWS Conn-0 Tunnel 2
resource "google_compute_vpn_tunnel" "tunnel_b" {
  name                            = "${local.name_prefix}-vpn-tunnel-b"
  project                         = var.gcp_project
  region                          = var.gcp_region
  vpn_gateway                     = var.gcp_ha_vpn_gateway
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 1
  shared_secret                   = var.vpn_tunnel2_psk
  router                          = var.gcp_router_name
  ike_version                     = 2
  description                     = "Tunnel B: GCP IF0 -> AWS Conn0 Tunnel2"
}

# Tunnel C: GCP Interface 1 <-> AWS Conn-1 Tunnel 1
resource "google_compute_vpn_tunnel" "tunnel_c" {
  name                            = "${local.name_prefix}-vpn-tunnel-c"
  project                         = var.gcp_project
  region                          = var.gcp_region
  vpn_gateway                     = var.gcp_ha_vpn_gateway
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 2
  shared_secret                   = var.vpn_tunnel1_psk
  router                          = var.gcp_router_name
  ike_version                     = 2
  description                     = "Tunnel C: GCP IF1 -> AWS Conn1 Tunnel1"
}

# Tunnel D: GCP Interface 1 <-> AWS Conn-1 Tunnel 2
resource "google_compute_vpn_tunnel" "tunnel_d" {
  name                            = "${local.name_prefix}-vpn-tunnel-d"
  project                         = var.gcp_project
  region                          = var.gcp_region
  vpn_gateway                     = var.gcp_ha_vpn_gateway
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws.id
  peer_external_gateway_interface = 3
  shared_secret                   = var.vpn_tunnel2_psk
  router                          = var.gcp_router_name
  ike_version                     = 2
  description                     = "Tunnel D: GCP IF1 -> AWS Conn1 Tunnel2"
}

###############################################################################
# GCP SIDE - Cloud Router Interfaces & BGP Peers
# Each tunnel gets a router interface (GCP BGP IP) and a peer (AWS BGP IP)
###############################################################################

# --- Tunnel A BGP ---

resource "google_compute_router_interface" "tunnel_a" {
  name       = "${local.name_prefix}-ri-tunnel-a"
  project    = var.gcp_project
  region     = var.gcp_region
  router     = var.gcp_router_name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_a.name
  # GCP BGP IP = CGW inside address from AWS VPN connection
  ip_range = "${aws_vpn_connection.conn_0.tunnel1_cgw_inside_address}/30"
}

resource "google_compute_router_peer" "tunnel_a" {
  name                      = "${local.name_prefix}-bgp-peer-a"
  project                   = var.gcp_project
  region                    = var.gcp_region
  router                    = var.gcp_router_name
  interface                 = google_compute_router_interface.tunnel_a.name
  # AWS BGP IP = VGW inside address from AWS VPN connection
  peer_ip_address           = aws_vpn_connection.conn_0.tunnel1_vgw_inside_address
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
}

# --- Tunnel B BGP ---

resource "google_compute_router_interface" "tunnel_b" {
  name       = "${local.name_prefix}-ri-tunnel-b"
  project    = var.gcp_project
  region     = var.gcp_region
  router     = var.gcp_router_name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_b.name
  ip_range   = "${aws_vpn_connection.conn_0.tunnel2_cgw_inside_address}/30"
}

resource "google_compute_router_peer" "tunnel_b" {
  name                      = "${local.name_prefix}-bgp-peer-b"
  project                   = var.gcp_project
  region                    = var.gcp_region
  router                    = var.gcp_router_name
  interface                 = google_compute_router_interface.tunnel_b.name
  peer_ip_address           = aws_vpn_connection.conn_0.tunnel2_vgw_inside_address
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
}

# --- Tunnel C BGP ---

resource "google_compute_router_interface" "tunnel_c" {
  name       = "${local.name_prefix}-ri-tunnel-c"
  project    = var.gcp_project
  region     = var.gcp_region
  router     = var.gcp_router_name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_c.name
  ip_range   = "${aws_vpn_connection.conn_1.tunnel1_cgw_inside_address}/30"
}

resource "google_compute_router_peer" "tunnel_c" {
  name                      = "${local.name_prefix}-bgp-peer-c"
  project                   = var.gcp_project
  region                    = var.gcp_region
  router                    = var.gcp_router_name
  interface                 = google_compute_router_interface.tunnel_c.name
  peer_ip_address           = aws_vpn_connection.conn_1.tunnel1_vgw_inside_address
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 200
}

# --- Tunnel D BGP ---

resource "google_compute_router_interface" "tunnel_d" {
  name       = "${local.name_prefix}-ri-tunnel-d"
  project    = var.gcp_project
  region     = var.gcp_region
  router     = var.gcp_router_name
  vpn_tunnel = google_compute_vpn_tunnel.tunnel_d.name
  ip_range   = "${aws_vpn_connection.conn_1.tunnel2_cgw_inside_address}/30"
}

resource "google_compute_router_peer" "tunnel_d" {
  name                      = "${local.name_prefix}-bgp-peer-d"
  project                   = var.gcp_project
  region                    = var.gcp_region
  router                    = var.gcp_router_name
  interface                 = google_compute_router_interface.tunnel_d.name
  peer_ip_address           = aws_vpn_connection.conn_1.tunnel2_vgw_inside_address
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 200
}
