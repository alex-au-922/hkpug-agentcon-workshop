resource "kubernetes_manifest" "vscode_service" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: v1
    kind: Service
    metadata:
      name: vscode
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      type: ClusterIP
      ports:
      - port: 80
        targetPort: 80
        name: vscode-web
        protocol: TCP
      - port: 8000
        targetPort: 8000
        name: vscode-unauthenticated
      selector:
        app: vscode
    EOT
  )
}
