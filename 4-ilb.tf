# Network load balancer, loadbalanding TCP traffic
# Source IP address is preserved (no proxy)
resource "google_compute_region_backend_service" "app-backend" {
  project               = google_project.project.project_id
  load_balancing_scheme = "INTERNAL"

  backend {
    group          = google_compute_instance_group_manager.grp-instance-group-1.instance_group
    balancing_mode = "CONNECTION"
  }
  backend {
    group          = google_compute_instance_group_manager.grp-instance-group-2.instance_group
    balancing_mode = "CONNECTION"
  }
  name        = "app-backend"
  protocol    = "TCP"
  timeout_sec = 10

  health_checks = [google_compute_health_check.tcp-health-check.id]
}

#Forwarding rule
resource "google_compute_forwarding_rule" "app-forwarding-rule" {
  provider              = google-beta
  region                = var.region
  project               = google_project.project.project_id
  name                  = "l4-ilb-forwarding-rule"
  backend_service       = google_compute_region_backend_service.app-backend.id
  ports                 = ["80"]
  ip_protocol           = "TCP"
  load_balancing_scheme = "INTERNAL"
  allow_global_access   = true
  network               = google_compute_network.vpc_network.id
  subnetwork            = google_compute_subnetwork.sb-subnet-a.id
}