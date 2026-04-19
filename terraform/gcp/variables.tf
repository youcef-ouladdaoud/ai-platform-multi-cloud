# GCP Variables

variable "project_id" {
  description = "GCP Project ID"
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
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone (optional, uses regional cluster if empty)"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "gpu_enabled" {
  description = "Enable GPU nodes for Ollama"
  type        = bool
  default     = false
}

variable "kubernetes_version" {
  description = "Kubernetes version (uses REGULAR channel if empty)"
  type        = string
  default     = ""
}
