terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------- Network ----------
resource "google_compute_network" "vpc" {
  name                    = "${var.prefix}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "tiers" {
  for_each                 = var.subnets
  name                     = "${var.prefix}-${each.key}-subnet"
  ip_cidr_range            = each.value
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# ---------- Firewall ----------
resource "google_compute_firewall" "iap_ssh" {
  name          = "${var.prefix}-allow-iap-ssh"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_firewall" "http" {
  name          = "${var.prefix}-allow-http"
  network       = google_compute_network.vpc.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}

resource "google_compute_firewall" "web_to_app" {
  name        = "${var.prefix}-allow-web-to-app"
  network     = google_compute_network.vpc.name
  direction   = "INGRESS"
  source_tags = ["web"]
  target_tags = ["app"]
  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }
  allow {
    protocol = "icmp"
  }
}

# ---------- Cloud Router + NAT ----------
resource "google_compute_router" "router" {
  name    = "${var.prefix}-router"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "${var.prefix}-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# ---------- Private app VM (no external IP) ----------
resource "google_compute_instance" "app" {
  name         = "${var.prefix}-app-vm"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["app"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.tiers["app"].id
    # no access_config block = no external IP
  }

  shielded_instance_config {
    enable_secure_boot = true
  }
}
