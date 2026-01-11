provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.web_zone
}

locals {
  vpc_name   = "sre-vpc"
  web_subnet = "10.20.0.0/24"
  db_subnet  = "10.20.1.0/24"
  web_tags   = ["web"]
  db_tags    = ["db"]
}

resource "google_compute_network" "vpc" {
  name                    = local.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "web" {
  name          = "${local.vpc_name}-web"
  region        = var.region
  ip_cidr_range = local.web_subnet
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "db" {
  name          = "${local.vpc_name}-db"
  region        = var.region
  ip_cidr_range = local.db_subnet
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "allow_http" {
  name    = "${local.vpc_name}-allow-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = local.web_tags
}

resource "google_compute_firewall" "allow_health_checks" {
  name    = "${local.vpc_name}-allow-hc"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = local.web_tags
}

resource "google_compute_firewall" "allow_mysql" {
  name    = "${local.vpc_name}-allow-mysql"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_ranges = [local.web_subnet]
  target_tags   = local.db_tags
}

resource "google_compute_instance_template" "web" {
  name_prefix  = "web-tmpl-"
  machine_type = "e2-medium"
  tags         = local.web_tags

  disk {
    source_image = "projects/debian-cloud/global/images/family/debian-12"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.web.id
    access_config {}
  }

  metadata_startup_script = file("${path.module}/scripts/web_server.sh")
}

resource "google_compute_instance_group_manager" "web" {
  name               = "web-mig"
  base_instance_name = "web"
  zone               = var.web_zone
  target_size        = var.web_instance_count

  version {
    instance_template = google_compute_instance_template.web.self_link
    name              = "primary"
  }

  named_port {
    name = "http"
    port = 80
  }
}

resource "google_compute_health_check" "http" {
  name               = "web-hc"
  check_interval_sec = 10
  timeout_sec        = 5

  http_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "web" {
  name        = "web-backend"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_instance_group_manager.web.instance_group
  }

  health_checks = [google_compute_health_check.http.id]
}

resource "google_compute_url_map" "web" {
  name            = "web-urlmap"
  default_service = google_compute_backend_service.web.self_link
}

resource "google_compute_target_http_proxy" "web" {
  name    = "web-proxy"
  url_map = google_compute_url_map.web.self_link
}

resource "google_compute_global_address" "lb" {
  name = "web-lb-ip"
}

resource "google_compute_global_forwarding_rule" "web" {
  name        = "web-forwarding-rule"
  target      = google_compute_target_http_proxy.web.self_link
  ip_address  = google_compute_global_address.lb.address
  port_range  = "80"
  ip_protocol = "TCP"
}

resource "google_compute_instance" "database" {
  name         = "db-vm"
  machine_type = "e2-small"
  zone         = var.db_zone
  tags         = local.db_tags

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
      size  = 60
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.db.id
  }

  metadata_startup_script = templatefile("${path.module}/scripts/db_server.sh.tpl", {
    db_name     = "appdb"
    db_user     = "appuser"
    db_password = var.database_password
    root_pass   = var.database_root_password
  })
}
