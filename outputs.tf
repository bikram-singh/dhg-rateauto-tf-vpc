output "vpc_id" {
  description = "The ID of the created VPC network."
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the created VPC network."
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The self link of the created VPC network."
  value       = google_compute_network.vpc.self_link
}

# Primary Subnet Outputs
output "primary_subnet_id" {
  description = "The ID of the primary subnet."
  value       = google_compute_subnetwork.primary_subnet.id
}

output "primary_subnet_name" {
  description = "The name of the primary subnet."
  value       = google_compute_subnetwork.primary_subnet.name
}

output "primary_subnet_cidr" {
  description = "The CIDR range of the primary subnet."
  value       = google_compute_subnetwork.primary_subnet.ip_cidr_range
}

output "primary_subnet_self_link" {
  description = "The self link of the primary subnet."
  value       = google_compute_subnetwork.primary_subnet.self_link
}

output "primary_secondary_ip_range" {
  description = "The secondary IP range for the primary subnet."
  value = {
    range_name    = google_compute_subnetwork.primary_subnet.secondary_ip_range[0].range_name
    ip_cidr_range = google_compute_subnetwork.primary_subnet.secondary_ip_range[0].ip_cidr_range
  }
}

# Secondary Subnet Outputs
output "secondary_subnet_id" {
  description = "The ID of the secondary subnet."
  value       = google_compute_subnetwork.secondary_subnet.id
}

output "secondary_subnet_name" {
  description = "The name of the secondary subnet."
  value       = google_compute_subnetwork.secondary_subnet.name
}

output "secondary_subnet_cidr" {
  description = "The CIDR range of the secondary subnet."
  value       = google_compute_subnetwork.secondary_subnet.ip_cidr_range
}

output "secondary_subnet_self_link" {
  description = "The self link of the secondary subnet."
  value       = google_compute_subnetwork.secondary_subnet.self_link
}

output "secondary_secondary_ip_range" {
  description = "The secondary IP range for the secondary subnet."
  value = {
    range_name    = google_compute_subnetwork.secondary_subnet.secondary_ip_range[0].range_name
    ip_cidr_range = google_compute_subnetwork.secondary_subnet.secondary_ip_range[0].ip_cidr_range
  }
}

# Cloud Router Outputs
output "cloud_router_id" {
  description = "The ID of the Cloud Router."
  value       = try(google_compute_router.router[0].id, null)
}

output "cloud_router_name" {
  description = "The name of the Cloud Router."
  value       = try(google_compute_router.router[0].name, null)
}

# Cloud NAT Outputs
output "cloud_nat_name" {
  description = "The name of the Cloud NAT."
  value       = try(google_compute_router_nat.nat[0].name, null)
}
