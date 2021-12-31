####### VPC NETWORK

resource "google_compute_network" "vpc_network" {
  name                    = "my-internal-app"
  auto_create_subnetworks = false
  mtu                     = 1460
  project                 = google_project.project.project_id
}


####### VPC SUBNETS

resource "google_compute_subnetwork" "sb-subnet-a" {
  name          = "subnet-a"
  project       = google_project.project.project_id
  ip_cidr_range = "10.10.20.0/24"
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_subnetwork" "sb-subnet-b" {
  name          = "subnet-b"
  project       = google_project.project.project_id
  ip_cidr_range = "10.10.30.0/24"
  network       = google_compute_network.vpc_network.id
}

####### FIREWALL

resource "google_compute_firewall" "fw-allow-internal" {
  name      = "allow-internal"
  project   = google_project.project.project_id
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }
  allow {
    protocol = "icmp"
  }

  source_ranges = [google_compute_subnetwork.sb-subnet-a.ip_cidr_range,
  google_compute_subnetwork.sb-subnet-b.ip_cidr_range]
}

resource "google_compute_firewall" "fw-allow-ssh" {
  name      = "allow-ssh"
  project   = google_project.project.project_id
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "fw-app-allow-http" {
  name      = "app-allow-http"
  project   = google_project.project.project_id
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }
  target_tags   = ["lb-backend"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "fw-app-allow-health-check" {
  name      = "app-allow-health-check"
  project   = google_project.project.project_id
  network   = google_compute_network.vpc_network.name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
  }
  target_tags   = ["lb-backend"]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

#### NAT

resource "google_compute_router" "router" {
  name    = "my-router"
  project = google_project.project.project_id
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  project                            = google_project.project.project_id
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}