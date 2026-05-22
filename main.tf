locals {
  vpc_name    = var.network_name
  subnet_name = var.subnetwork_name
}

# ----------------------------------------------------------------------------
# VPC Network
# ----------------------------------------------------------------------------
resource "google_compute_network" "vpc" {
  name                            = local.vpc_name
  project                         = var.project_id
  auto_create_subnetworks         = false
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = false

  description = "VPC network for ${var.stage} environment"
}

# ----------------------------------------------------------------------------
# Subnet (single) with secondary ranges for GKE pods and services
# ----------------------------------------------------------------------------
resource "google_compute_subnetwork" "subnet" {
  name          = local.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.subnet_primary_cidr

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = var.pods_range_name
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = var.services_range_name
    ip_cidr_range = var.services_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ----------------------------------------------------------------------------
# Cloud Router (required for Private Google Access / NAT)
# ----------------------------------------------------------------------------
resource "google_compute_router" "router" {
  name    = "${local.vpc_name}-router"
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id
}

# ----------------------------------------------------------------------------
# Cloud NAT (allows private nodes to reach the internet for image pulls, etc.)
# ----------------------------------------------------------------------------
resource "google_compute_router_nat" "nat" {
  name                               = "${local.vpc_name}-nat"
  project                            = var.project_id
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ----------------------------------------------------------------------------
# Firewall — deny all ingress (default-deny baseline)
# ----------------------------------------------------------------------------
resource "google_compute_firewall" "deny_all_ingress" {
  name      = "${local.vpc_name}-deny-all-ingress"
  project   = var.project_id
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

# ----------------------------------------------------------------------------
# Firewall — allow internal traffic within the VPC
# ----------------------------------------------------------------------------
resource "google_compute_firewall" "allow_internal" {
  name      = "${local.vpc_name}-allow-internal"
  project   = var.project_id
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    var.subnet_primary_cidr,
    var.pods_cidr,
    var.services_cidr,
  ]
}
