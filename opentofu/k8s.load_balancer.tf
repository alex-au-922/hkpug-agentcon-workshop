resource "google_compute_global_address" "load_balancer" {
  provider = google
  name     = "${var.stack_prefix}-load-balancer-${var.env}"
}

resource "kubernetes_namespace_v1" "gateway" {
  provider = kubernetes
  metadata {
    name = "${var.gateway_config.namespace}-${var.env}"
    labels = {
      role = "gateway"
    }
  }
}

resource "kubernetes_manifest" "gateway" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: gateway.networking.k8s.io/v1beta1
    kind: Gateway
    metadata:
      name: ${var.stack_prefix}-gateway-${var.env}
      namespace: ${kubernetes_namespace_v1.gateway.metadata[0].name}
      annotations:
        networking.gke.io/certmap: ${google_certificate_manager_certificate_map.wildcard.name}
    spec:
      gatewayClassName: gke-l7-global-external-managed
      listeners:
      - name: http
        protocol: HTTP
        port: 80
        allowedRoutes:
          namespaces:
            from: All
      - name: https
        protocol: HTTPS
        port: 443
        allowedRoutes:
          namespaces:
            from: All
      addresses:
      - type: NamedAddress
        value: ${google_compute_global_address.load_balancer.name}
   EOT
  )
}

resource "kubernetes_manifest" "vscode_httproutes" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: ${each.key}
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      parentRefs:
        - name: ${kubernetes_manifest.gateway.manifest.metadata.name}
          namespace: ${kubernetes_manifest.gateway.manifest.metadata.namespace}
          sectionName: https
      hostnames:
        - ${each.key}.${var.domain_config.second_level_domain}
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          backendRefs:
          - name: vscode
            port: 80
    EOT
  )
}

resource "kubernetes_manifest" "vscode_http_redirect_routes" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: gateway.networking.k8s.io/v1
    kind: HTTPRoute
    metadata:
      name: ${each.key}-http-redirect
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      parentRefs:
        - name: ${kubernetes_manifest.gateway.manifest.metadata.name}
          namespace: ${kubernetes_manifest.gateway.manifest.metadata.namespace}
          sectionName: http
      hostnames:
        - ${each.key}.${var.domain_config.second_level_domain}
      rules:
        - matches:
            - path:
                type: PathPrefix
                value: /
          filters:
            - type: RequestRedirect
              requestRedirect:
                scheme: https
                statusCode: 301
    EOT
  )
}

resource "kubernetes_manifest" "vscode_healthcheck" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: networking.gke.io/v1
    kind: HealthCheckPolicy
    metadata:
      name: healthcheck
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      default:
        checkIntervalSec: 10
        timeoutSec: 10
        healthyThreshold: 3
        unhealthyThreshold: 5
        config:
          type: HTTP
          httpHealthCheck:
            portSpecification: USE_FIXED_PORT
            port: 8000
            requestPath: /
      targetRef:
        group: ""
        kind: Service
        name: vscode
    EOT
  )
}
