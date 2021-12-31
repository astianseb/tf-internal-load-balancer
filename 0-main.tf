variable "region" {}

variable "project_name" {}

variable "billing_account" {}

locals {
  zone-a = "${var.region}-a"
  zone-b = "${var.region}-b"
}

provider "google" {
  region = var.region
}
