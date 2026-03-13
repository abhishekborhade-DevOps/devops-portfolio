###############################################################################
# GCP Infrastructure Module
#
# Provisions:
#   - VPC Network (custom mode, no auto-subnets)
#   - Subnet with VPC Flow Logs
#   - Firewall Rules (IAP SSH, internal, AWS cross-cloud)
#   - Cloud Router (for BGP dynamic routing with AWS)
#   - HA VPN Gateway (two interfaces for redundancy)
#   - VM Test Instance (Shielded VM, no external IP)
###############################################################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

#------------------------------------------------------------------------------
# VPC Network (custom mode - no auto subnets)
#------------------------------------------------------------------------------

resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  project                 = var.gcp_project
  auto_create_subnetworks = false
  description             = "Multi-cloud VPN demo VPC - custom mode network"
}

#------------------------------------------------------------------------------
# Subnet with Flow Logs
#------------------------------------------------------------------------------

resource "google_compute_subnetwork" "main" {
  name                     = "${local.name_prefix}-subnet"
  project                  = var.gcp_project
  region                   = var.gcp_region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

#------------------------------------------------------------------------------
# Firewall Rules
#------------------------------------------------------------------------------

# Allow SSH via Google IAP (Identity-Aware Proxy) - no external IP needed
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${local.name_prefix}-allow-iap-ssh"
  project = var.gcp_project
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP proxy IP range - only source for SSH
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["ssh-iap"]
  description   = "Allow SSH via Google Identity-Aware Proxy (no external IP required)"
  priority      = 1000
}

# Allow ICMP from AWS VPC - for cross-cloud ping testing
resource "google_compute_firewall" "allow_icmp_from_aws" {
  name    = "${local.name_prefix}-allow-icmp-aws"
  project = var.gcp_project
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.aws_vpc_cidr]
  target_tags   = ["multi-cloud-test"]
  description   = "Allow ICMP from AWS VPC for cross-cloud connectivity testing"
  priority      = 1000
}

# Allow SSH from AWS VPC - for cross-cloud SSH testing
resource "google_compute_firewall" "allow_ssh_from_aws" {
  name    = "${local.name_prefix}-allow-ssh-aws"
  project = var.gcp_project
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [var.aws_vpc_cidr]
  target_tags   = ["multi-cloud-test"]
  description   = "Allow SSH from AWS VPC over VPN tunnel"
  priority      = 1000
}

# Allow all internal traffic within the GCP subnet
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.name_prefix}-allow-internal"
  project = var.gcp_project
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.subnet_cidr]
  description   = "Allow all traffic within GCP subnet"
  priority      = 1000
}

#------------------------------------------------------------------------------
# Cloud Router (BGP dynamic routing for VPN)
#------------------------------------------------------------------------------

resource "google_compute_router" "main" {
  name    = "${local.name_prefix}-cloud-router"
  project = var.gcp_project
  region  = var.gcp_region
  network = google_compute_network.main.id

  bgp {
    asn               = var.gcp_bgp_asn
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    # Explicitly advertise GCP subnet to AWS
    advertised_ip_ranges {
      range       = var.subnet_cidr
      description = "GCP primary subnet advertised via BGP to AWS"
    }
  }

  description = "Cloud Router for HA VPN BGP sessions - peers with AWS VGW"
}

#------------------------------------------------------------------------------
# HA VPN Gateway (two interfaces for high availability)
#------------------------------------------------------------------------------

resource "google_compute_ha_vpn_gateway" "main" {
  name    = "${local.name_prefix}-ha-vpn-gw"
  project = var.gcp_project
  region  = var.gcp_region
  network = google_compute_network.main.id

  description = "HA VPN Gateway - provides two external IPs for AWS VPN redundancy"
}

#------------------------------------------------------------------------------
# VM Test Instance (Shielded VM, private-only)
#------------------------------------------------------------------------------

data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_instance" "test_vm" {
  name         = "${local.name_prefix}-test-vm"
  project      = var.gcp_project
  machine_type = var.machine_type
  zone         = var.gcp_zone

  tags = ["ssh-iap", "multi-cloud-test"]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
      size  = 20
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = google_compute_network.main.id
    subnetwork = google_compute_subnetwork.main.id
    # No access_config block = no external IP (private-only, accessed via IAP or VPN)
  }

  # OS Login instead of SSH keys in metadata (more secure)
  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y tcpdump traceroute iputils-ping netcat-openbsd curl
    echo "=============================================" >> /etc/motd
    echo "  GCP Test VM - Multi-Cloud VPN Demo" >> /etc/motd
    echo "=============================================" >> /etc/motd
  EOF

  # Shielded VM features for enhanced security
  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    project     = var.project_name
    environment = var.environment
    managed-by  = "terraform"
    role        = "test-instance"
  }

  description = "Private test VM for multi-cloud VPN connectivity validation"
}
