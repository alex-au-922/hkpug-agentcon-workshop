resource "kubernetes_manifest" "vscode_sa" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: ${each.key}-vscode-sa
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
      labels:
        app: vscode
        tenant: ${each.key}
      annotations:
        iam.gke.io/gcp-service-account: ${google_service_account.workload_identity_user_sa[each.key].email}
    EOT
  )
}
