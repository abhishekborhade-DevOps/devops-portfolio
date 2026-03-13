###############################################################################
# AWS Module Outputs
###############################################################################

output "vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "AWS VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_ip" {
  description = "Elastic IP of NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "vpn_gateway_id" {
  description = "Virtual Private Gateway (VPN Gateway) ID - used by VPN module"
  value       = aws_vpn_gateway.main.id
}

output "private_route_table_id" {
  description = "Private route table ID - VPN routes are propagated here"
  value       = aws_route_table.private.id
}

output "bastion_public_ip" {
  description = "Bastion host public IP address"
  value       = aws_instance.bastion.public_ip
}

output "bastion_instance_id" {
  description = "Bastion EC2 instance ID"
  value       = aws_instance.bastion.id
}

output "private_instance_ip" {
  description = "Private EC2 instance private IP (target for cross-cloud ping test)"
  value       = aws_instance.private.private_ip
}

output "private_instance_id" {
  description = "Private EC2 instance ID"
  value       = aws_instance.private.id
}

output "key_name" {
  description = "EC2 key pair name used for SSH"
  value       = aws_instance.bastion.key_name
}
