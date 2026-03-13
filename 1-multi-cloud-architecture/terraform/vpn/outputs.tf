###############################################################################
# VPN Module Outputs
###############################################################################

#------------------------------------------------------------------------------
# AWS VPN Connection Outputs
#------------------------------------------------------------------------------

output "aws_vpn_connection_0_id" {
  description = "AWS VPN Connection 0 ID (connects VGW to GCP HA VPN interface 0)"
  value       = aws_vpn_connection.conn_0.id
}

output "aws_vpn_connection_1_id" {
  description = "AWS VPN Connection 1 ID (connects VGW to GCP HA VPN interface 1)"
  value       = aws_vpn_connection.conn_1.id
}

output "aws_tunnel0_1_address" {
  description = "AWS VPN Connection 0 - Tunnel 1 external IP (peer for GCP Tunnel A)"
  value       = aws_vpn_connection.conn_0.tunnel1_address
}

output "aws_tunnel0_2_address" {
  description = "AWS VPN Connection 0 - Tunnel 2 external IP (peer for GCP Tunnel B)"
  value       = aws_vpn_connection.conn_0.tunnel2_address
}

output "aws_tunnel1_1_address" {
  description = "AWS VPN Connection 1 - Tunnel 1 external IP (peer for GCP Tunnel C)"
  value       = aws_vpn_connection.conn_1.tunnel1_address
}

output "aws_tunnel1_2_address" {
  description = "AWS VPN Connection 1 - Tunnel 2 external IP (peer for GCP Tunnel D)"
  value       = aws_vpn_connection.conn_1.tunnel2_address
}

#------------------------------------------------------------------------------
# GCP VPN Outputs
#------------------------------------------------------------------------------

output "gcp_external_vpn_gateway_name" {
  description = "GCP External VPN Gateway name (represents AWS side)"
  value       = google_compute_external_vpn_gateway.aws.name
}

output "gcp_vpn_tunnel_a_name" {
  description = "GCP VPN Tunnel A name"
  value       = google_compute_vpn_tunnel.tunnel_a.name
}

output "gcp_vpn_tunnel_b_name" {
  description = "GCP VPN Tunnel B name"
  value       = google_compute_vpn_tunnel.tunnel_b.name
}

output "gcp_vpn_tunnel_c_name" {
  description = "GCP VPN Tunnel C name"
  value       = google_compute_vpn_tunnel.tunnel_c.name
}

output "gcp_vpn_tunnel_d_name" {
  description = "GCP VPN Tunnel D name"
  value       = google_compute_vpn_tunnel.tunnel_d.name
}

#------------------------------------------------------------------------------
# BGP Peer Outputs
#------------------------------------------------------------------------------

output "gcp_bgp_peer_a_ip" {
  description = "AWS BGP IP for Tunnel A (VGW inside address)"
  value       = aws_vpn_connection.conn_0.tunnel1_vgw_inside_address
}

output "gcp_bgp_peer_b_ip" {
  description = "AWS BGP IP for Tunnel B (VGW inside address)"
  value       = aws_vpn_connection.conn_0.tunnel2_vgw_inside_address
}

output "aws_customer_gateway_0_id" {
  description = "AWS Customer Gateway 0 ID (points to GCP HA VPN interface 0)"
  value       = aws_customer_gateway.gcp_if0.id
}

output "aws_customer_gateway_1_id" {
  description = "AWS Customer Gateway 1 ID (points to GCP HA VPN interface 1)"
  value       = aws_customer_gateway.gcp_if1.id
}
