
resource "google_compute_health_check" "tcp-health-check" {
  name               = "tcp-health-check"
  project            = local.project_id
  timeout_sec        = 1
  check_interval_sec = 1


  tcp_health_check {
    port = "80"
  }
}


// ------------- Instance Group A
resource "google_compute_instance_template" "tmpl-instance-group-1" {
  name                 = "instance-group-1"
  project              = local.project_id
  description          = "SG instance group of preemptible hosts"
  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"
  can_ip_forward       = false
  tags                 = ["lb-backend"]

  scheduling {
    preemptible       = true
    automatic_restart = false

  }

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network            = google_compute_network.vpc_network.name
    subnetwork         = google_compute_subnetwork.sb-subnet-a.name
    subnetwork_project = local.project_id
  }

  metadata = {
    startup-script-url = "gs://cloud-training/gcpnet/ilb/startup.sh"
  }
}

#MIG-a
resource "google_compute_instance_group_manager" "grp-instance-group-1" {
  name               = "instance-group-1"
  project            = local.project_id
  base_instance_name = "mig-a"
  zone               = local.zone-a
  version {
    instance_template = google_compute_instance_template.tmpl-instance-group-1.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.tcp-health-check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "obj-my-autoscaler-a" {
  name    = "my-autoscaler-a"
  project = local.project_id
  zone    = local.zone-a
  target  = google_compute_instance_group_manager.grp-instance-group-1.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 45

    cpu_utilization {
      target = 0.8
    }
  }
}


//----------------Instance Group B

resource "google_compute_instance_template" "tmpl-instance-group-2" {
  name                 = "instance-group-2"
  project              = local.project_id
  description          = "SG instance group of preemptible hosts"
  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"
  can_ip_forward       = false
  tags                 = ["lb-backend"]

  scheduling {
    preemptible       = true
    automatic_restart = false

  }

  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network            = google_compute_network.vpc_network.name
    subnetwork         = google_compute_subnetwork.sb-subnet-b.name
    subnetwork_project = local.project_id
  }

  metadata = {
    startup-script-url = "gs://cloud-training/gcpnet/ilb/startup.sh"
  }
}

resource "google_compute_instance_group_manager" "grp-instance-group-2" {
  name               = "instance-group-2"
  project            = local.project_id
  base_instance_name = "mig-b"
  zone               = local.zone-b
  version {
    instance_template = google_compute_instance_template.tmpl-instance-group-2.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.tcp-health-check.id
    initial_delay_sec = 300
  }
}

resource "google_compute_autoscaler" "obj-my-autoscaler-b" {
  name    = "my-autoscaler-b"
  project = local.project_id
  zone    = local.zone-b
  target  = google_compute_instance_group_manager.grp-instance-group-2.id

  autoscaling_policy {
    max_replicas    = 5
    min_replicas    = 1
    cooldown_period = 45

    cpu_utilization {
      target = 0.8
    }
  }
}