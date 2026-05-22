stage      = "stage"
project_id = "dhg-vaccine-rateauto-nonpord"
region     = "us-central1"

# Networking
network_name    = "dhg-rateauto-stage-vpc"
subnetwork_name = "dhg-rateauto-stage-us-subnet"

# CIDR ranges — adjust to fit your IP plan
subnet_primary_cidr = "10.30.0.0/20"
pods_cidr           = "10.31.0.0/16"
services_cidr       = "10.32.0.0/20"

# Secondary range names
pods_range_name     = "gke-pods"
services_range_name = "gke-services"

resource_labels = {
  environment  = "stage"
  service-tier = "p3"
}

