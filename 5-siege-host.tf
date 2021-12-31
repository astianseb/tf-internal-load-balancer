# Instance to host siege (testing tool for LB)
# usage: siege -i --concurrent=50 http://<lb-ip>
#

resource "google_compute_instance" "siege-host" {
  name         = "siege-host"
  machine_type = "e2-medium"
  zone         = "europe-central2-a"
  project      = google_project.project.project_id

  tags = ["siege"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.name
    subnetwork = google_compute_subnetwork.sb-subnet-a.self_link
  }

  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  metadata = {
    enable-oslogin = true
  }


  metadata_startup_script = <<-EOF1
      #! /bin/bash
      set -euo pipefail

      export DEBIAN_FRONTEND=noninteractive
      apt-get update
      apt-get install -y siege
     EOF1

}