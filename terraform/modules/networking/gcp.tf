# GCP Network Resources
resource "google_compute_network" "main" {
  count                   = var.cloud_provider == "gcp" ? 1 : 0
  name                    = "ai-platform-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"
}

resource "google_compute_subnetwork" "public" {
  count         = var.cloud_provider == "gcp" ? length(var.public_subnet_cidrs) : 0
  name          = "ai-platform-public-${count.index + 1}"
  ip_cidr_range = var.public_subnet_cidrs[count.index]
  network       = google_compute_network.main[0].id
  region        = var.region

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "private" {
  count         = var.cloud_provider == "gcp" ? length(var.private_subnet_cidrs) : 0
  name          = "ai-platform-private-${count.index + 1}"
  ip_cidr_range = var.private_subnet_cidrs[count.index]
  network       = google_compute_network.main[0].id
  region        = var.region

  private_ip_google_access = true
}

resource "google_compute_router" "main" {
  count   = var.cloud_provider == "gcp" ? 1 : 0
  name    = "ai-platform-router"
  network = google_compute_network.main[0].id
  region  = var.region
}

resource "google_compute_address" "nat" {
  count  = var.cloud_provider == "gcp" ? 1 : 0
  name   = "ai-platform-nat-ip"
  region = var.region
}

resource "google_compute_router_nat" "main" {
  count                              = var.cloud_provider == "gcp" ? 1 : 0
  name                               = "ai-platform-nat"
  router                             = google_compute_router.main[0].name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.nat[0].self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.private[0].id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_internal" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  name  = "ai-platform-allow-internal"
  network = google_compute_network.main[0].name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.vpc_cidr]
}

resource "google_compute_firewall" "allow_external" {
  count = var.cloud_provider == "gcp" ? 1 : 0
  name  = "ai-platform-allow-external"
  network = google_compute_network.main[0].name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "8080", "11434"]
  }

  source_ranges = ["0.0.0.0/0"]
}
