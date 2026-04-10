variable "stack_prefix" {
  description = "Prefix for the stack for resource management"
  type        = string
}

variable "env" {
  description = "Environment of stack"
  type        = string
}

variable "region" {
  description = "Region of the stack"
  type        = string
}

variable "vscode_extensions" {
  description = "VS Code extensions to prefetch and bake into the IDE image"
  type = list(object({
    id        = string
    source    = string
    publisher = string
    name      = string
    version   = string
    target    = string
    url       = string
    filename  = string
  }))
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token for domain management"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP Project ID for the stack"
  type        = string
}

variable "enabled_services" {
  description = "Enabled Services APIs in GCP"
  type        = list(string)
}

variable "vpc_config" {
  description = "Configuration of VPC"
  type = object({
    main_cidr = string
    secondary_ip_ranges = map(object({
      range_name    = string
      ip_cidr_range = string
    }))
  })
}

variable "gke_config" {
  description = "Configuration of GKE"
  type = object({
    cluster = object({
      location = string
    })
    node_pools = map(object({
      spot         = bool
      machine_type = string
      node_count = object({
        min = number
        max = number
      })
      disk_size = number
      labels    = map(string)
      node_taints = list(object({
        key    = string
        value  = string
        effect = string
      }))
    }))
  })
}

variable "gateway_config" {
  description = "Configuration of Gateway"
  type = object({
    namespace = string
  })
}

variable "domain_config" {
  description = "Configuration of domain"
  type = object({
    second_level_domain = string
    zone_id             = string
  })
}

variable "tenant_config" {
  description = "Configuration for tenants"
  type = object({
    max_tenant_num         = number
    curr_tenant_num        = number
    vscode_password_length = number
    storage                = string
  })
}

variable "istio_config" {
  description = "Configuration for Istio ambient mesh"
  type = object({
    namespace        = string
    profile          = string
    default_revision = string
    dataplane_mode   = string
    base = object({
      name       = string
      repository = string
      chart      = string
      version    = string
      value_file = string
    })
    cni = object({
      name               = string
      namespace          = string
      repository         = string
      chart              = string
      version            = string
      value_file         = string
      cni_bin_dir        = string
      dns_capture        = bool
      exclude_namespaces = list(string)
    })
    istiod = object({
      name            = string
      repository      = string
      chart           = string
      version         = string
      value_file      = string
      access_log_file = string
    })
    ztunnel = object({
      name                    = string
      repository              = string
      chart                   = string
      version                 = string
      value_file              = string
      resource_quotas_enabled = bool
      resource_quota_pods     = number
    })
  })
}

variable "kubearmor_config" {
  description = "Configuration for KubeArmor"
  type = object({
    name                         = string
    namespace                    = string
    repository                   = string
    chart                        = string
    version                      = string
    value_file                   = string
    environment_name             = string
    relay_enabled                = bool
    image_pull_policy            = string
    default_file_posture         = string
    default_capabilities_posture = string
    default_network_posture      = string
    visibility                   = string
    alert_throttling             = bool
    max_alert_per_sec            = number
    throttle_sec                 = number
    match_args                   = bool
  })
}
