# Test Environment VPC Configuration
project_id   = "dhg-vaccine-rateauto-nonpord"

vpc_name     = "dhg-rateauto-test-vpc"
routing_mode = "REGIONAL"

# Primary Subnet Configuration (Test) - used for GKE Pods
primary_subnet_name          = "dhg-rateauto-test-primary-subnet"
primary_subnet_cidr          = "10.20.1.0/24"
primary_secondary_range_name = "gke-pods"
primary_secondary_cidr       = "10.21.0.0/16"

# Secondary Subnet Configuration (Test) - used for GKE Services
secondary_subnet_name          = "dhg-rateauto-test-secondary-subnet"
secondary_subnet_cidr          = "10.20.2.0/24"
secondary_secondary_range_name = "gke-services"
secondary_secondary_cidr       = "10.22.0.0/16"

# Cloud Router & NAT Configuration
router_name = "dhg-rateauto-test-router"
nat_name    = "dhg-rateauto-test-nat"

# Mandatory labels
aide_id      = "dhg-vaccine-rateauto"
environment  = "test"
service_tier = "p3"
