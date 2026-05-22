# Dev Environment VPC Configuration
project_id   = "dhg-vaccine-rateauto-nonpord"

vpc_name     = "dhg-rateauto-dev-vpc"
routing_mode = "REGIONAL"

# Primary Subnet Configuration (Dev) - used for GKE Pods
primary_subnet_name          = "dhg-rateauto-dev-primary-subnet"
primary_subnet_cidr          = "10.0.1.0/24"
primary_secondary_range_name = "gke-pods"
primary_secondary_cidr       = "10.1.0.0/16"

# Secondary Subnet Configuration (Dev) - used for GKE Services
secondary_subnet_name          = "dhg-rateauto-dev-secondary-subnet"
secondary_subnet_cidr          = "10.0.2.0/24"
secondary_secondary_range_name = "gke-services"
secondary_secondary_cidr       = "10.2.0.0/16"

# Cloud Router & NAT Configuration
router_name = "dhg-rateauto-dev-router"
nat_name    = "dhg-rateauto-dev-nat"

# Mandatory labels
aide_id      = "dhg-vaccine-rateauto"
environment  = "dev"
service_tier = "p3"
