locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  # Cluster connection details from OKE
  cluster_endpoint = try("https://${oci_containerengine_cluster.primary.endpoints[0].private_endpoint}", "")
  
  # Get kubeconfig content and decode from base64
  cluster_kubeconfig = try(data.oci_containerengine_cluster_kube_config.primary.content, "")
  cluster_ca_cert    = try(local.cluster_kubeconfig != "" ? base64decode(jsondecode(local.cluster_kubeconfig).clusters[0].cluster["certificate-authority-data"]) : "", "")
  cluster_token      = try(local.cluster_kubeconfig != "" ? jsondecode(local.cluster_kubeconfig).users[0].user.token : "", "")
}

data "oci_containerengine_cluster_kube_config" "primary" {
  cluster_id = oci_containerengine_cluster.primary.id
}

# VCN
resource "oci_core_vcn" "main" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_ocid
  display_name   = "${local.cluster_name}-vcn"
  dns_label      = "aiplatform"
}

# Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-igw"
}

# NAT Gateway
resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-nat"
}

# Service Gateway
resource "oci_core_service_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-sgw"
  
  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Route Tables
resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-public-rt"
  
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

resource "oci_core_route_table" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-private-rt"
  
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }
  
  route_rules {
    destination       = "all-services"
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.main.id
  }
}

# Security Lists
resource "oci_core_security_list" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-public-sl"
  
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }
  
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }
  
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }
  
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"
    tcp_options {
      min = 6443
      max = 6443
    }
  }
}

resource "oci_core_security_list" "private" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.cluster_name}-private-sl"
  
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
  
  ingress_security_rules {
    protocol = "all"
    source   = var.vcn_cidr
  }
}

# Subnets
resource "oci_core_subnet" "public" {
  count             = 3
  cidr_block        = cidrsubnet(var.vcn_cidr, 8, count.index)
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  display_name      = "${local.cluster_name}-public-${count.index + 1}"
  security_list_ids = [oci_core_security_list.public.id]
  route_table_id    = oci_core_route_table.public.id
  dhcp_options_id   = oci_core_vcn.main.default_dhcp_options_id
  dns_label         = "public${count.index + 1}"
}

resource "oci_core_subnet" "private" {
  count             = 3
  cidr_block        = cidrsubnet(var.vcn_cidr, 8, count.index + 10)
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  display_name      = "${local.cluster_name}-private-${count.index + 1}"
  security_list_ids = [oci_core_security_list.private.id]
  route_table_id    = oci_core_route_table.private.id
  dhcp_options_id   = oci_core_vcn.main.default_dhcp_options_id
  dns_label         = "private${count.index + 1}"
  prohibit_public_ip_on_vnic = true
}

# OKE Cluster
resource "oci_containerengine_cluster" "primary" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = local.cluster_name
  vcn_id             = oci_core_vcn.main.id
  
  options {
    service_lb_subnet_ids = oci_core_subnet.public[*].id
    
    add_ons {
      is_kubernetes_dashboard_enabled = false
      is_tiller_enabled              = false
    }
    
    admission_controller_options {
      is_pod_security_policy_enabled = true
    }
  }
  
  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public[0].id
  }
}

# Node Pool
resource "oci_containerengine_node_pool" "general" {
  cluster_id     = oci_containerengine_cluster.primary.id
  compartment_id = var.compartment_ocid
  name           = "${local.cluster_name}-general"
  node_shape     = var.node_shape
  
  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory
  }
  
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private[0].id
    }
    
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
      subnet_id           = oci_core_subnet.private[1].id
    }
    
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[2].name
      subnet_id           = oci_core_subnet.private[2].id
    }
    
    size = var.node_count
  }
  
  node_source_details {
    image_id    = data.oci_core_images.latest_image.images[0].id
    source_type = "IMAGE"
  }
  
  initial_node_labels {
    key   = "workload"
    value = "general"
  }
}

# GPU Node Pool (if enabled)
resource "oci_containerengine_node_pool" "gpu" {
  count          = var.gpu_enabled ? 1 : 0
  cluster_id     = oci_containerengine_cluster.primary.id
  compartment_id = var.compartment_ocid
  name           = "${local.cluster_name}-gpu"
  node_shape     = var.gpu_node_shape
  
  node_config_details {
    placement_configs {
      availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
      subnet_id           = oci_core_subnet.private[0].id
    }
    
    size = 1
  }
  
  node_source_details {
    image_id    = data.oci_core_images.latest_gpu_image.images[0].id
    source_type = "IMAGE"
  }
  
  initial_node_labels {
    key   = "workload"
    value = "gpu"
  }
  
  initial_node_labels {
    key   = "nvidia.com/gpu"
    value = "true"
  }
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

data "oci_core_images" "latest_image" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_core_images" "latest_gpu_image" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Oracle Linux"
  operating_system_version = "8"
  shape                    = var.gpu_node_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Object Storage bucket for models
resource "oci_objectstorage_bucket" "models" {
  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "${local.cluster_name}-models"
  storage_tier   = "Standard"
  versioning     = "Enabled"
}

data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

# Install NGINX Ingress Controller
resource "helm_release" "nginx_ingress" {
  name       = "nginx-ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.8.3"
  namespace  = "ingress-nginx"
  
  create_namespace = true
}

# Install cert-manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "1.13.0"
  namespace  = "cert-manager"
  
  create_namespace = true
  
  set {
    name  = "installCRDs"
    value = "true"
  }
}
