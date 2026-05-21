# Stage Environment VPC Configuration
project_id = "dhg-vaccine-rateauto-nonpord"

vpc_name  = "dhg-rateauto-stage-vpc"
routing_mode = "REGIONAL"

# Primary Subnet Configuration (Stage)
primary_subnet_name      = "dhg-rateauto-stage-primary-subnet"
primary_subnet_cidr      = "10.10.1.0/24"
primary_secondary_range_name = "primary-gke-pods"
primary_secondary_cidr   = "10.11.0.0/16"

# Secondary Subnet Configuration (Stage)
secondary_subnet_name    = "dhg-rateauto-stage-secondary-subnet"
secondary_subnet_cidr    = "10.10.2.0/24"
secondary_secondary_range_name = "secondary-gke-pods"
secondary_secondary_cidr = "10.12.0.0/16"

# Cloud Router & NAT Configuration
router_name = "dhg-rateauto-stage-router"
nat_name    = "dhg-rateauto-stage-nat"

# Mandatory labels
aide_id      = "dhg-vaccine-rateauto"
environment  = "stage"
service_tier = "p2"
