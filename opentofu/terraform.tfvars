stack_prefix = "hkpug-agentcon"
env          = "prod"
region       = "asia-east2"
enabled_services = [
  "container",
  "certificatemanager",
  "aiplatform"
]
vpc_config = {
  main_cidr = "10.0.0.0/16",
  secondary_ip_ranges = {
    pod = {
      range_name    = "pod-range",
      ip_cidr_range = "10.1.0.0/16"
    }
    service = {
      range_name    = "service-range",
      ip_cidr_range = "10.2.0.0/16"
    }
  }
}
gke_config = {
  cluster = {
    location = "BALANCED"
  }
  node_pools = {
    public = {
      spot         = false
      machine_type = "e2-standard-8"
      node_count = {
        min = 1
        max = 10
      }
      disk_size   = 40
      labels      = {}
      node_taints = []
    }
  }
}

gateway_config = {
  namespace = "gateway"
}

domain_config = {
  second_level_domain = "agentcon-workshop.python.hk"
  zone_id             = "9a8e44e64e747f46dcb63067682f5f67"
}

tenant_config = {
  max_tenant_num         = 80
  curr_tenant_num        = 1
  vscode_password_length = 4
  storage                = "10Gi"
}
