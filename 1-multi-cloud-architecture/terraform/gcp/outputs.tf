###############################################################################
# GCP Module Outputs
###############################################################################

output "network_name" {
  description = "GCP VPC network name"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "GCP VPC network self link (used by VPN module)"
  value       = google_compute_network.main.self_link
}

output "subnet_name" {
  description = "GCP subnet name"
  value       = google_compute_subnetwork.main.name
}

output "subnet_self_link" {
  description = "GCP subnet self link"
  value       = google_compute_subnetwork.main.self_link
}

output "cloud_router_name" {
  description = "Cloud Router name (used by VPN module for BGP interface configuration)"
  value       = google_compute_router.main.name
}

output "ha_vpn_gateway_name" {
  description = "HA VPN Gateway name (used by VPN module for tunnel creation)"
  value       = google_compute_ha_vpn_gateway.main.name
}

output "ha_vpn_ip_0" {
  description = "HA VPN Gateway interface 0 external IP (used as AWS Customer Gateway IP)"
  value       = google_compute_ha_vpn_gateway.main.vpn_interfaces[0].ip_address
}

output "ha_vpn_ip_1" {
  description = "HA VPN Gateway interface 1 external IP (used as AWS Customer Gateway IP)"
  value       = google_compute_ha_vpn_gateway.main.vpn_interfaces[1].ip_address
}

output "test_vm_name" {
  description = "GCP test VM instance name"
  value       = google_compute_instance.test_vm.name
}

output "test_vm_internal_ip" {
  description = "GCP test VM internal IP (target for cross-cloud connectivity testing)"
  value       = google_compute_instance.test_vm.network_interface[0].network_ip
}

output "test_vm_zone" {
  description = "GCP test VM zone (needed for gcloud SSH command)"
  value       = google_compute_instance.test_vm.zone
}

output "test_vm_self_link" {
  description = "GCP test VM self link"
  value       = google_compute_instance.test_vm.self_link
}
