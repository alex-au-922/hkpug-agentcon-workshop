resource "kubernetes_namespace_v1" "istio_system" {
  provider = kubernetes

  metadata {
    name = var.istio_config.namespace
    labels = {
      role = "service-mesh"
    }
  }
}

resource "kubernetes_namespace_v1" "kubearmor" {
  provider = kubernetes

  metadata {
    name = var.kubearmor_config.namespace
    labels = {
      role = "security"
    }
  }
}

resource "helm_release" "istio_base" {
  provider         = helm
  name             = var.istio_config.base.name
  repository       = var.istio_config.base.repository
  chart            = var.istio_config.base.chart
  namespace        = kubernetes_namespace_v1.istio_system.metadata[0].name
  version          = var.istio_config.base.version
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/${var.istio_config.base.value_file}", {
      default_revision = var.istio_config.default_revision
    }),
  ]

  depends_on = [
    google_container_node_pool.this,
    kubernetes_namespace_v1.istio_system,
  ]
}

resource "helm_release" "istio_cni" {
  provider         = helm
  name             = var.istio_config.cni.name
  repository       = var.istio_config.cni.repository
  chart            = var.istio_config.cni.chart
  namespace        = var.istio_config.cni.namespace
  version          = var.istio_config.cni.version
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/${var.istio_config.cni.value_file}", {
      cni_bin_dir        = var.istio_config.cni.cni_bin_dir
      profile            = var.istio_config.profile
      dns_capture        = var.istio_config.cni.dns_capture
      exclude_namespaces = var.istio_config.cni.exclude_namespaces
    }),
  ]

  depends_on = [
    helm_release.istio_base,
  ]
}

resource "helm_release" "istiod" {
  provider         = helm
  name             = var.istio_config.istiod.name
  repository       = var.istio_config.istiod.repository
  chart            = var.istio_config.istiod.chart
  namespace        = kubernetes_namespace_v1.istio_system.metadata[0].name
  version          = var.istio_config.istiod.version
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/${var.istio_config.istiod.value_file}", {
      profile         = var.istio_config.profile
      cluster_name    = google_container_cluster.this.name
      access_log_file = var.istio_config.istiod.access_log_file
    }),
  ]

  depends_on = [
    helm_release.istio_base,
    helm_release.istio_cni,
  ]
}

resource "helm_release" "ztunnel" {
  provider         = helm
  name             = var.istio_config.ztunnel.name
  repository       = var.istio_config.ztunnel.repository
  chart            = var.istio_config.ztunnel.chart
  namespace        = kubernetes_namespace_v1.istio_system.metadata[0].name
  version          = var.istio_config.ztunnel.version
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/${var.istio_config.ztunnel.value_file}", {
      profile                 = var.istio_config.profile
      cluster_name            = google_container_cluster.this.name
      resource_quotas_enabled = var.istio_config.ztunnel.resource_quotas_enabled
      resource_quota_pods     = var.istio_config.ztunnel.resource_quota_pods
    }),
  ]

  depends_on = [
    helm_release.istio_base,
    helm_release.istio_cni,
    helm_release.istiod,
  ]
}

resource "helm_release" "kubearmor" {
  provider         = helm
  name             = var.kubearmor_config.name
  repository       = var.kubearmor_config.repository
  chart            = var.kubearmor_config.chart
  namespace        = kubernetes_namespace_v1.kubearmor.metadata[0].name
  version          = var.kubearmor_config.version
  create_namespace = false
  cleanup_on_fail  = true
  atomic           = true
  wait             = true
  timeout          = 600

  values = [
    templatefile("${path.module}/${var.kubearmor_config.value_file}", {
      environment_name             = var.kubearmor_config.environment_name
      relay_enabled                = var.kubearmor_config.relay_enabled
      image_pull_policy            = var.kubearmor_config.image_pull_policy
      default_file_posture         = var.kubearmor_config.default_file_posture
      default_capabilities_posture = var.kubearmor_config.default_capabilities_posture
      default_network_posture      = var.kubearmor_config.default_network_posture
      visibility                   = var.kubearmor_config.visibility
      alert_throttling             = var.kubearmor_config.alert_throttling
      max_alert_per_sec            = var.kubearmor_config.max_alert_per_sec
      throttle_sec                 = var.kubearmor_config.throttle_sec
      match_args                   = var.kubearmor_config.match_args
    }),
  ]

  depends_on = [
    google_container_node_pool.this,
    kubernetes_namespace_v1.kubearmor,
  ]
}
