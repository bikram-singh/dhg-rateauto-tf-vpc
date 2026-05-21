resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  description             = "Environment: ${var.environment}"
}

# Primary Subnet
resource "google_compute_subnetwork" "primary_subnet" {
  name          = var.primary_subnet_name
  ip_cidr_range = var.primary_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  secondary_ip_range {
    range_name    = var.primary_secondary_range_name
    ip_cidr_range = var.primary_secondary_cidr
  }

  private_ip_google_access = var.enable_private_ip_google_access

  labels = {
    aide-id      = var.aide_id
    environment  = var.environment
    service-tier = var.service_tier
    subnet-type  = "primary"
  }
}

# Secondary Subnet
resource "google_compute_subnetwork" "secondary_subnet" {
  name          = var.secondary_subnet_name
  ip_cidr_range = var.secondary_subnet_cidr
  region        = var.region
  network       = google_compute_network.vpc.id
  project       = var.project_id

  secondary_ip_range {
    range_name    = var.secondary_secondary_range_name
    ip_cidr_range = var.secondary_secondary_cidr
  }

  private_ip_google_access = var.enable_private_ip_google_access

  labels = {
    aide-id      = var.aide_id
    environment  = var.environment
    service-tier = var.service_tier
    subnet-type  = "secondary"
  }
}

# Optional: Cloud Router for NAT (if needed)
resource "google_compute_router" "router" {
  count   = var.enable_cloud_router ? 1 : 0
  name    = var.router_name
  project = var.project_id
  region  = var.region
  network = google_compute_network.vpc.id

  labels = {
    aide-id      = var.aide_id
    environment  = var.environment
    service-tier = var.service_tier
  }
}

# Optional: Cloud NAT (if needed)
resource "google_compute_router_nat" "nat" {
  count                              = var.enable_cloud_nat ? 1 : 0
  name                               = var.nat_name
  router                             = google_compute_router.router[0].name
  region                             = google_compute_router.router[0].region
  nat_ip_allocate_option             = var.nat_ip_allocate_option
  source_subnetwork_ip_ranges_to_nat = var.source_subnetwork_ip_ranges_to_nat
  auto_network_tier                  = var.nat_auto_network_tier

  log_config {
    enable = var.enable_nat_logs
    filter = var.nat_log_filter
  }
}