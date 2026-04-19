# Oracle Cloud Outputs

output "cluster_name" {
  description = "OKE cluster name"
  value       = oci_containerengine_cluster.primary.name
}

output "cluster_id" {
  description = "OKE cluster ID"
  value       = oci_containerengine_cluster.primary.id
}

output "cluster_endpoint" {
  description = "OKE cluster endpoint"
  value       = local.cluster_endpoint
  sensitive   = true
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.primary.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0"
}

output "vcn_id" {
  description = "VCN ID"
  value       = oci_core_vcn.main.id
}

output "bucket_name" {
  description = "Object Storage bucket for models"
  value       = oci_objectstorage_bucket.models.name
}

output "bucket_namespace" {
  description = "Object Storage namespace"
  value       = oci_objectstorage_bucket.models.namespace
}
