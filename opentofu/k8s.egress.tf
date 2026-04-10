resource "kubernetes_manifest" "workshop_open_egress" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: networking.istio.io/v1beta1
    kind: ServiceEntry
    metadata:
      name: workshop-open-egress
      namespace: ${kubernetes_namespace_v1.istio_system.metadata[0].name}
    spec:
      hosts:
      - api.agentcon.local
      - evil.com
      endpoints:
      - address: workshop-egress.workshop-system.svc.cluster.local
        ports:
          http: 80
      ports:
      - number: 80
        name: http
        protocol: HTTP
      resolution: DNS
      location: MESH_EXTERNAL
    EOT
  )

  depends_on = [
    helm_release.istiod,
    kubernetes_manifest.workshop_egress_service,
  ]
}
