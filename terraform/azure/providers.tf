# Azure Provider Configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.75"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ai-platform-terraform-rg"
    storage_account_name = "aiplatformtfstate"
    container_name       = "tfstate"
    key                  = "azure/terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.primary.kube_config.0.host
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
  client_certificate     = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.primary.kube_config.0.host
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.cluster_ca_certificate)
    client_certificate     = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.primary.kube_config.0.client_key)
  }
}
