# Oracle Cloud Network Resources (OCI)

resource "oci_core_vcn" "main" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  cidr_block     = var.vpc_cidr
  compartment_id = var.compartment_id
  display_name   = "ai-platform-vcn"
  dns_label      = "aiplatform"
}

resource "oci_core_internet_gateway" "main" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "ai-platform-igw"
}

resource "oci_core_nat_gateway" "main" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "ai-platform-nat"
}

resource "oci_core_subnet" "public" {
  count             = var.cloud_provider == "oracle" ? length(var.public_subnet_cidrs) : 0
  cidr_block        = var.public_subnet_cidrs[count.index]
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.main[0].id
  display_name      = "ai-platform-public-${count.index + 1}"
  dns_label         = "public${count.index + 1}"
  security_list_ids = [oci_core_security_list.public[0].id]
  route_table_id    = oci_core_route_table.public[0].id
  dhcp_options_id   = oci_core_vcn.main[0].default_dhcp_options_id
}

resource "oci_core_subnet" "private" {
  count             = var.cloud_provider == "oracle" ? length(var.private_subnet_cidrs) : 0
  cidr_block        = var.private_subnet_cidrs[count.index]
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.main[0].id
  display_name      = "ai-platform-private-${count.index + 1}"
  dns_label         = "private${count.index + 1}"
  security_list_ids = [oci_core_security_list.private[0].id]
  route_table_id    = oci_core_route_table.private[0].id
  dhcp_options_id   = oci_core_vcn.main[0].default_dhcp_options_id
  prohibit_public_ip_on_vnic = true
}

resource "oci_core_route_table" "public" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "ai-platform-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main[0].id
  }
}

resource "oci_core_route_table" "private" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "ai-platform-private-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main[0].id
  }
}

resource "oci_core_public_ip" "nat" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  display_name   = "ai-platform-nat-ip"
  lifetime       = "RESERVED"
}

resource "oci_core_security_list" "public" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "ai-platform-public-sl"

  # Allow all outbound
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Allow inbound SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow inbound HTTP/HTTPS
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 443
      max = 443
    }
  }

  # Allow inbound for Open WebUI and Ollama
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 8080
      max = 8080
    }
  }

  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      min = 11434
      max = 11434
    }
  }
}

resource "oci_core_security_list" "private" {
  count          = var.cloud_provider == "oracle" ? 1 : 0
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.main[0].id
  display_name   = "ai-platform-private-sl"

  # Allow all outbound through NAT
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Allow internal VPC traffic
  ingress_security_rules {
    protocol = "all"
    source   = var.vpc_cidr
  }
}

variable "compartment_id" {
  description = "OCI Compartment ID"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region for cloud resources"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Azure Resource Group Name"
  type        = string
  default     = ""
}
