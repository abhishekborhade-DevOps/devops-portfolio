###############################################################################
# AWS Infrastructure Module
#
# Provisions:
#   - VPC with DNS support
#   - Public subnet + Internet Gateway
#   - Private subnet + NAT Gateway
#   - Route tables with proper associations
#   - Security Groups (bastion + private)
#   - EC2 Bastion Host (public)
#   - EC2 Private Test Instance
#   - Virtual Private Gateway (for VPN)
#   - VPN Route Propagation
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

#------------------------------------------------------------------------------
# Internet Gateway
#------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

#------------------------------------------------------------------------------
# Subnets
#------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet"
    Tier = "public"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${local.name_prefix}-private-subnet"
    Tier = "private"
  }
}

#------------------------------------------------------------------------------
# NAT Gateway (enables private subnet instances to reach internet)
#------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "${local.name_prefix}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# Route Tables
#------------------------------------------------------------------------------

# Public Route Table - routes 0.0.0.0/0 via Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table - routes 0.0.0.0/0 via NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#------------------------------------------------------------------------------
# Virtual Private Gateway (VPN Gateway)
#------------------------------------------------------------------------------

resource "aws_vpn_gateway" "main" {
  vpc_id          = aws_vpc.main.id
  amazon_side_asn = var.aws_bgp_asn

  tags = {
    Name = "${local.name_prefix}-vgw"
  }
}

# Enable BGP route propagation: VPN routes appear automatically in route table
resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.private.id
}

#------------------------------------------------------------------------------
# Security Groups
#------------------------------------------------------------------------------

# Bastion Host Security Group - allows SSH from specified CIDR
resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-sg-"
  description = "Security group for bastion host - allows SSH ingress"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDR only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-bastion-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Private Instance Security Group - allows traffic from bastion + GCP VPN
resource "aws_security_group" "private" {
  name_prefix = "${local.name_prefix}-private-sg-"
  description = "Security group for private test instance"
  vpc_id      = aws_vpc.main.id

  # SSH from bastion only
  ingress {
    description     = "SSH from bastion host"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  # ICMP (ping) from GCP subnet - for connectivity testing
  ingress {
    description = "ICMP from GCP subnet (cross-cloud ping test)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.gcp_subnet_cidr]
  }

  # All traffic from within VPC
  ingress {
    description = "All traffic from VPC CIDR"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-private-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

#------------------------------------------------------------------------------
# EC2 Instances
#------------------------------------------------------------------------------

# Bastion Host - entry point into private network
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = var.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y tcpdump traceroute nmap-ncat
    echo "====================================" >> /etc/motd
    echo "  AWS Bastion - Multi-Cloud VPN Demo" >> /etc/motd
    echo "====================================" >> /etc/motd
  EOF
  )

  tags = {
    Name = "${local.name_prefix}-bastion"
    Role = "bastion"
  }
}

# Private Test Instance - used for cross-cloud connectivity testing
resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private.id]
  key_name               = var.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y tcpdump traceroute nmap-ncat
    echo "=============================================" >> /etc/motd
    echo "  AWS Private Instance - Multi-Cloud VPN Test" >> /etc/motd
    echo "=============================================" >> /etc/motd
  EOF
  )

  tags = {
    Name = "${local.name_prefix}-private-instance"
    Role = "test-instance"
  }
}
