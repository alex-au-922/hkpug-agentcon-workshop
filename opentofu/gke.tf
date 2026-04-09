resource "google_service_account" "gke" {
  account_id   = "${var.stack_prefix}-gke-${var.env}"
  display_name = "${var.stack_prefix}-gke-sa-${var.env}"
}

resource "google_container_cluster" "this" {
  name                                     = "${var.stack_prefix}-gke-${var.env}"
  location                                 = var.region
  deletion_protection                      = false
  datapath_provider                        = "ADVANCED_DATAPATH"
  enable_cilium_clusterwide_network_policy = true
  enable_fqdn_network_policy               = true

  cluster_autoscaling {
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
  }

  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  monitoring_config {
    enable_components = []
    managed_prometheus {
      enabled = false
    }
    advanced_datapath_observability_config {
      enable_metrics = false
      enable_relay   = false
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.stack_prefix}-${var.vpc_config.secondary_ip_ranges.pod.range_name}-${var.env}"
    services_secondary_range_name = "${var.stack_prefix}-${var.vpc_config.secondary_ip_ranges.service.range_name}-${var.env}"
    stack_type                    = "IPV4"
  }

  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = google_compute_network.k8s_stack.self_link
  subnetwork               = google_compute_subnetwork.k8s_stack.self_link

  workload_identity_config {
    workload_pool = "${data.google_client_config.provider.project}.svc.id.goog"
  }

  depends_on = [
    google_compute_network.k8s_stack
  ]
}

resource "google_container_node_pool" "this" {
  for_each = var.gke_config.node_pools
  name     = "${var.stack_prefix}-${each.key}-${var.env}"
  location = var.region
  cluster  = google_container_cluster.this.name

  node_config {
    spot         = each.value.spot
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
    labels = merge(
      {
        usage = each.key
      },
      each.value.labels
    )

    dynamic "taint" {
      for_each = each.value.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }
  }

  autoscaling {
    total_min_node_count = each.value.node_count.min
    total_max_node_count = each.value.node_count.max
    location_policy      = var.gke_config.cluster.location
  }

  depends_on = [google_container_cluster.this]
}


