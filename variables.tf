variable "project_id" {
  description = "The ID of the project in which to create resources."
  type        = string
}

variable "region" {
  description = "The region in which to create resources."
  type        = string
  default     = "us-central1"
}

variable "vpc_name" {
  description = "The name of the VPC network."
  type        = string
}

variable "routing_mode" {
  description = "The network routing mode (REGIONAL or GLOBAL)."
  type        = string
  default     = "REGIONAL"
  
  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "The routing_mode must be either REGIONAL or GLOBAL."
  }
}

# Primary Subnet Variables
variable "primary_subnet_name" {
  description = "The name of the primary subnet."
  type        = string
}

variable "primary_subnet_cidr" {
  description = "The CIDR range for the primary subnet (e.g., 10.0.1.0/24)."
  type        = string
}

variable "primary_secondary_range_name" {
  description = "The name of the secondary IP range for the primary subnet."
  type        = string
  default     = "primary-secondary-range"
}

variable "primary_secondary_cidr" {
  description = "The secondary CIDR range for the primary subnet (e.g., 10.1.0.0/16)."
  type        = string
}

# Secondary Subnet Variables
variable "secondary_subnet_name" {
  description = "The name of the secondary subnet."
  type        = string
}

variable "secondary_subnet_cidr" {
  description = "The CIDR range for the secondary subnet (e.g., 10.0.2.0/24)."
  type        = string
}

variable "secondary_secondary_range_name" {
  description = "The name of the secondary IP range for the secondary subnet."
  type        = string
  default     = "secondary-secondary-range"
}

variable "secondary_secondary_cidr" {
  description = "The secondary CIDR range for the secondary subnet (e.g., 10.2.0.0/16)."
  type        = string
}

# Common Subnet Configuration
variable "enable_private_ip_google_access" {
  description = "Enable Private Google Access on the subnets."
  type        = bool
  default     = true
}

# Cloud Router Configuration (Optional)
variable "enable_cloud_router" {
  description = "Enable Cloud Router for NAT."
  type        = bool
  default     = false
}

variable "router_name" {
  description = "The name of the Cloud Router."
  type        = string
  default     = ""
}

# Cloud NAT Configuration (Optional)
variable "enable_cloud_nat" {
  description = "Enable Cloud NAT."
  type        = bool
  default     = false
}

variable "nat_name" {
  description = "The name of the Cloud NAT."
  type        = string
  default     = ""
}

variable "nat_ip_allocate_option" {
  description = "How external IPs should be allocated for Cloud NAT (AUTO_ONLY or MANUAL_ONLY)."
  type        = string
  default     = "AUTO_ONLY"
  
  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "The nat_ip_allocate_option must be either AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "source_subnetwork_ip_ranges_to_nat" {
  description = "Subnetworks of the VPC to NAT all traffic from (ALL_SUBNETWORKS_ALL_IP_RANGES, ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES, or LIST_OF_SUBNETWORKS)."
  type        = string
  default     = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
}

variable "nat_auto_network_tier" {
  description = "The network tier to use for the Cloud NAT (PREMIUM or STANDARD)."
  type        = string
  default     = "PREMIUM"
  
  validation {
    condition     = contains(["PREMIUM", "STANDARD"], var.nat_auto_network_tier)
    error_message = "The nat_auto_network_tier must be either PREMIUM or STANDARD."
  }
}

variable "enable_nat_logs" {
  description = "Enable logging for Cloud NAT."
  type        = bool
  default     = false
}

variable "nat_log_filter" {
  description = "Specifies the desired filtering of logs on this NAT (ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL)."
  type        = string
  default     = "ERRORS_ONLY"
  
  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
    error_message = "The nat_log_filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

# Mandatory labels to satisfy org policy
variable "aide_id" {
  description = "The AIDE ID for resource labeling."
  type        = string
}

variable "environment" {
  description = "The environment (dev, stage, test, prod)."
  type        = string
}

variable "service_tier" {
  description = "The service tier for resource labeling."
  type        = string
}
