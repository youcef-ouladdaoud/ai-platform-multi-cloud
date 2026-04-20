# Oracle Cloud Variables

variable "tenancy_ocid" {
  description = "OCI Tenancy OCID"
  type        = string
}

variable "user_ocid" {
  description = "OCI User OCID"
  type        = string
}

variable "fingerprint" {
  description = "OCI API Key Fingerprint"
  type        = string
}

variable "private_key_path" {
  description = "Path to OCI private key"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI Compartment OCID"
  type        = string
}

variable "namespace" {
  description = "OCI Object Storage Namespace"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "ai-platform"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "OCI Region"
  type        = string
  default     = "us-ashburn-1"
}

variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "v1.31.1"
}

variable "node_shape" {
  description = "Shape for worker nodes"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "node_ocpus" {
  description = "OCPUs per node"
  type        = number
  default     = 2
}

variable "node_memory" {
  description = "Memory in GB per node"
  type        = number
  default     = 16
}

variable "node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "gpu_enabled" {
  description = "Enable GPU nodes for Ollama"
  type        = bool
  default     = false
}

variable "gpu_node_shape" {
  description = "GPU node shape"
  type        = string
  default     = "VM.GPU.A10.1"
}
