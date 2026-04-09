resource "google_compute_network" "k8s_stack" {
  provider                        = google
  name                            = "${var.stack_prefix}-vpc-${var.env}"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
  depends_on = [
    google_project_service.this
  ]
}

resource "google_compute_subnetwork" "k8s_stack" {
  name = "${var.stack_prefix}-gke-subnet-${var.env}"

  ip_cidr_range = var.vpc_config.main_cidr
  region        = var.region

  stack_type = "IPV4_ONLY"

  network = google_compute_network.k8s_stack.id

  dynamic "secondary_ip_range" {
    for_each = var.vpc_config.secondary_ip_ranges
    content {
      range_name    = "${var.stack_prefix}-${secondary_ip_range.value.range_name}-${var.env}"
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_route" "default" {
  name             = "${var.stack_prefix}-igw-route-${var.env}"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.k8s_stack.name
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
}

resource "google_compute_firewall" "load_balancer" {
  name     = "${var.stack_prefix}-allow-load-balancer-${var.env}"
  network  = google_compute_network.k8s_stack.name
  disabled = false

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  allow {
    protocol = "all"
  }
}

