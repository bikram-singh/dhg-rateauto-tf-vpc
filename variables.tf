variable "project_id" {
  description = "The GCP project ID to provision the VPC in"
  type        = string
}

variable "region" {
  description = "The GCP region for the VPC and subnet"
  type        = string
  default     = "us-central1"
}

variable "stage" {
  description = "Environment label (dev / test / stage / prod)"
  type        = string
}

# ----------------------------------------------------------------------------
# Network naming
# ----------------------------------------------------------------------------

variable "network_name" {
  description = "Name of the VPC network to create"
  type        = string
}

variable "subnetwork_name" {
  description = "Name of the single subnet to create inside the VPC"
  type        = string
}

# ----------------------------------------------------------------------------
# CIDR ranges
# ----------------------------------------------------------------------------

variable "subnet_primary_cidr" {
  description = "Primary CIDR range for the subnet (GKE nodes)"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary IP range used for GKE Pods"
  type        = string
  default     = "gke-pods"
}

variable "pods_cidr" {
  description = "CIDR range for the GKE Pods secondary range"
  type        = string
}

variable "services_range_name" {
  description = "Name of the secondary IP range used for GKE Services"
  type        = string
  default     = "gke-services"
}

variable "services_cidr" {
  description = "CIDR range for the GKE Services secondary range"
  type        = string
}

# ----------------------------------------------------------------------------
# Labels
# ----------------------------------------------------------------------------

variable "resource_labels" {
  description = "GCP resource labels to apply to all resources"
  type        = map(string)
  default     = {}
}
