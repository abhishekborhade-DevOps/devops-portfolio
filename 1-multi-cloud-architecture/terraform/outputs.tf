###############################################################################
# Root Outputs - Useful values after deployment
###############################################################################

#------------------------------------------------------------------------------
# AWS Outputs
#------------------------------------------------------------------------------

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = module.aws_infra.vpc_id
}

output "aws_bastion_public_ip" {
  description = "Public IP of AWS Bastion Host - use this to SSH into AWS"
  value       = module.aws_infra.bastion_public_ip
}

output "aws_private_instance_ip" {
  description = "Private IP of AWS test EC2 instance"
  value       = module.aws_infra.private_instance_ip
}

output "aws_vpn_gateway_id" {
  description = "AWS Virtual Private Gateway ID"
  value       = module.aws_infra.vpn_gateway_id
}

#------------------------------------------------------------------------------
# GCP Outputs
#------------------------------------------------------------------------------

output "gcp_network_name" {
  description = "GCP VPC network name"
  value       = module.gcp_infra.network_name
}

output "gcp_test_vm_name" {
  description = "GCP test VM instance name"
  value       = module.gcp_infra.test_vm_name
}

output "gcp_test_vm_internal_ip" {
  description = "GCP test VM internal IP - use this to test cross-cloud connectivity"
  value       = module.gcp_infra.test_vm_internal_ip
}

output "gcp_ha_vpn_ip_0" {
  description = "GCP HA VPN Gateway Interface 0 external IP"
  value       = module.gcp_infra.ha_vpn_ip_0
}

output "gcp_ha_vpn_ip_1" {
  description = "GCP HA VPN Gateway Interface 1 external IP"
  value       = module.gcp_infra.ha_vpn_ip_1
}

#------------------------------------------------------------------------------
# VPN Outputs
#------------------------------------------------------------------------------

output "aws_vpn_connection_0_id" {
  description = "AWS VPN Connection 0 ID (connects to GCP interface 0)"
  value       = module.vpn_connectivity.aws_vpn_connection_0_id
}

output "aws_vpn_connection_1_id" {
  description = "AWS VPN Connection 1 ID (connects to GCP interface 1)"
  value       = module.vpn_connectivity.aws_vpn_connection_1_id
}

output "gcp_external_vpn_gateway_name" {
  description = "GCP External VPN Gateway name (represents AWS side)"
  value       = module.vpn_connectivity.gcp_external_vpn_gateway_name
}

#------------------------------------------------------------------------------
# Connectivity Testing Summary
#------------------------------------------------------------------------------

output "connectivity_test_commands" {
  description = "Commands to test cross-cloud connectivity"
  value = <<-EOT
    =====================================================================
    CONNECTIVITY TESTING COMMANDS
    =====================================================================

    1. SSH to AWS Bastion:
       ssh -i ~/.ssh/${module.aws_infra.key_name}.pem ec2-user@${module.aws_infra.bastion_public_ip}

    2. From bastion, SSH to AWS Private Instance:
       ssh -i ~/.ssh/${module.aws_infra.key_name}.pem ec2-user@${module.aws_infra.private_instance_ip}

    3. From AWS Private Instance, ping GCP VM:
       ping ${module.gcp_infra.test_vm_internal_ip}

    4. SSH to GCP VM via IAP:
       gcloud compute ssh ${module.gcp_infra.test_vm_name} \
         --zone=${module.gcp_infra.test_vm_zone} \
         --project=${var.gcp_project_id} \
         --tunnel-through-iap

    5. From GCP VM, ping AWS Private Instance:
       ping ${module.aws_infra.private_instance_ip}
    =====================================================================
  EOT
}
