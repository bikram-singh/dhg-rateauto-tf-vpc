output "network_name" {
  description = "Name of the created VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "Self-link / ID of the created VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "URI of the VPC network (used by GKE cluster referencing)"
  value       = google_compute_network.vpc.self_link
}

output "subnetwork_name" {
  description = "Name of the created subnet"
  value       = google_compute_subnetwork.subnet.name
}

output "subnetwork_self_link" {
  description = "URI of the created subnet"
  value       = google_compute_subnetwork.subnet.self_link
}

output "subnet_primary_cidr" {
  description = "Primary CIDR of the subnet"
  value       = google_compute_subnetwork.subnet.ip_cidr_range
}

output "pods_range_name" {
  description = "Secondary range name for GKE Pods"
  value       = var.pods_range_name
}

output "services_range_name" {
  description = "Secondary range name for GKE Services"
  value       = var.services_range_name
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.nat.name
}
