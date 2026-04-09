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
