resource "kubernetes_manifest" "network_policy" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: allow-same-namespace-and-ingress
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      podSelector: {}
      policyTypes:
      - Ingress
      ingress:
      - from:
        - ipBlock:
            cidr: 35.191.0.0/16
        - ipBlock:
            cidr: 130.211.0.0/22
        - podSelector: {}
    EOT
  )
}

