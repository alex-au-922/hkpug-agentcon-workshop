stack_prefix = "hkpug-agentcon"
env          = "prod"
region       = "asia-southeast1"

vscode_extensions = [
  {
    id        = "anthropic.claude-code"
    source    = "openvsx"
    publisher = "Anthropic"
    name      = "claude-code"
    version   = "2.1.100"
    target    = "linux-x64"
    url       = ""
    filename  = "Anthropic.claude-code-2.1.100.vsix"
  },
  {
    id        = "github.copilot-chat"
    source    = "direct"
    publisher = ""
    name      = ""
    version   = ""
    target    = ""
    url       = "https://github.gallery.vsassets.io/_apis/public/gallery/publisher/github/extension/copilot-chat/0.43.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
    filename  = "github.copilot-chat-0.43.0.vsix"
  },
  {
    id        = "ms-python.debugpy"
    source    = "openvsx"
    publisher = "ms-python"
    name      = "debugpy"
    version   = "2025.18.0"
    target    = "linux-x64"
    url       = ""
    filename  = "ms-python.debugpy-2025.18.0-linux-x64.vsix"
  },
  {
    id        = "ms-python.python"
    source    = "direct"
    publisher = "ms-python"
    name      = "python"
    version   = "2026.4.0"
    target    = "linux-x64"
    url       = "https://ms-python.gallery.vsassets.io/_apis/public/gallery/publisher/ms-python/extension/python/2026.4.0/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage?targetPlatform=linux-x64"
    filename  = "ms-python.python-2026.4.0.vsix"
  },
  {
    id        = "ms-python.vscode-pylance"
    source    = "direct"
    publisher = ""
    name      = ""
    version   = ""
    target    = ""
    url       = "https://ms-python.gallery.vsassets.io/_apis/public/gallery/publisher/ms-python/extension/vscode-pylance/2026.2.1/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
    filename  = "ms-python.vscode-pylance-2026.2.1.vsix"
  },
  {
    id        = "ms-toolsai.jupyter"
    source    = "openvsx"
    publisher = "ms-toolsai"
    name      = "jupyter"
    version   = "2025.9.1"
    target    = "universal"
    url       = ""
    filename  = "ms-toolsai.jupyter-2025.9.1.vsix"
  },
  {
    id        = "openai.chatgpt"
    source    = "openvsx"
    publisher = "openai"
    name      = "chatgpt"
    version   = "26.5406.31014"
    target    = "linux-x64"
    url       = ""
    filename  = "openai.chatgpt-26.5406.31014.vsix"
  },
  {
    id        = "redhat.vscode-yaml"
    source    = "openvsx"
    publisher = "redhat"
    name      = "vscode-yaml"
    version   = "1.22.2026041008"
    target    = "universal"
    url       = ""
    filename  = "redhat.vscode-yaml-1.22.2026041008.vsix"
  },
  {
    id        = "sst-dev.opencode"
    source    = "openvsx"
    publisher = "sst-dev"
    name      = "opencode"
    version   = "0.0.13"
    target    = "universal"
    url       = ""
    filename  = "sst-dev.opencode-0.0.13.vsix"
  },
  {
    id        = "tamasfe.even-better-toml"
    source    = "openvsx"
    publisher = "tamasfe"
    name      = "even-better-toml"
    version   = "0.21.2"
    target    = "universal"
    url       = ""
    filename  = "tamasfe.even-better-toml-0.21.2.vsix"
  },
]

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
    workshop = {
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
    shared = {
      spot         = false
      machine_type = "e2-standard-4"
      node_count = {
        min = 2
        max = 3
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

istio_config = {
  namespace        = "istio-system"
  profile          = "ambient"
  default_revision = "default"
  dataplane_mode   = "ambient"
  base = {
    name       = "istio-base"
    repository = "https://istio-release.storage.googleapis.com/charts"
    chart      = "base"
    version    = "1.29.1"
    value_file = "manifests/istio-base.values.yaml.tftpl"
  }
  cni = {
    name               = "istio-cni"
    namespace          = "kube-system"
    repository         = "https://istio-release.storage.googleapis.com/charts"
    chart              = "cni"
    version            = "1.29.1"
    value_file         = "manifests/istio-cni-ambient.values.yaml.tftpl"
    cni_bin_dir        = "/home/kubernetes/bin"
    dns_capture        = true
    exclude_namespaces = ["kube-system", "istio-system", "kubearmor"]
  }
  istiod = {
    name            = "istiod"
    repository      = "https://istio-release.storage.googleapis.com/charts"
    chart           = "istiod"
    version         = "1.29.1"
    value_file      = "manifests/istiod-ambient.values.yaml.tftpl"
    access_log_file = "/dev/stdout"
  }
  ztunnel = {
    name                    = "ztunnel"
    repository              = "https://istio-release.storage.googleapis.com/charts"
    chart                   = "ztunnel"
    version                 = "1.29.1"
    value_file              = "manifests/ztunnel-ambient.values.yaml.tftpl"
    resource_quotas_enabled = true
    resource_quota_pods     = 10
  }
}

kubearmor_config = {
  name                         = "kubearmor"
  namespace                    = "kubearmor"
  repository                   = "https://kubearmor.github.io/charts"
  chart                        = "kubearmor"
  version                      = "v1.6.16"
  value_file                   = "manifests/kubearmor.values.yaml.tftpl"
  environment_name             = "GKE"
  relay_enabled                = false
  image_pull_policy            = "IfNotPresent"
  default_file_posture         = "audit"
  default_capabilities_posture = "audit"
  default_network_posture      = "audit"
  visibility                   = "process,file,network,capabilities"
  alert_throttling             = true
  max_alert_per_sec            = 20
  throttle_sec                 = 30
  match_args                   = true
}
