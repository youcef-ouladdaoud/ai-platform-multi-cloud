output "vpc_id" {
  description = "ID of the VPC"
  value       = var.cloud_provider == "aws" ? aws_vpc.main[0].id : var.cloud_provider == "gcp" ? google_compute_network.main[0].id : var.cloud_provider == "azure" ? azurerm_virtual_network.main[0].id : oci_core_vcn.main[0].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = var.cloud_provider == "aws" ? aws_subnet.public[*].id : var.cloud_provider == "gcp" ? google_compute_subnetwork.public[*].id : var.cloud_provider == "azure" ? azurerm_subnet.public[*].id : oci_core_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = var.cloud_provider == "aws" ? aws_subnet.private[*].id : var.cloud_provider == "gcp" ? google_compute_subnetwork.private[*].id : var.cloud_provider == "azure" ? azurerm_subnet.private[*].id : oci_core_subnet.private[*].id
}

output "nat_gateway_ips" {
  description = "IPs of NAT gateways"
  value       = var.cloud_provider == "aws" ? aws_eip.nat[*].public_ip : var.cloud_provider == "gcp" ? google_compute_address.nat[*].address : var.cloud_provider == "azure" ? azurerm_public_ip.nat[*].ip_address : oci_core_public_ip.nat[*].ip_address
}

variable "cloud_provider" {
  description = "Cloud provider (aws, gcp, azure, oracle)"
  type        = string
}
