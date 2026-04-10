resource "kubernetes_manifest" "vscode_namespace_role" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: vscode-workshop-user
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    rules:
    - apiGroups: [""]
      resources: ["pods", "pods/log", "services", "endpoints", "events"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["apps"]
      resources: ["deployments", "replicasets", "statefulsets"]
      verbs: ["get", "list", "watch"]
    - apiGroups: ["security.kubearmor.com"]
      resources: ["kubearmorpolicies"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    - apiGroups: ["security.istio.io"]
      resources: ["authorizationpolicies", "peerauthentications"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    - apiGroups: ["networking.istio.io"]
      resources: ["serviceentries"]
      verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    EOT
  )
}

resource "kubernetes_manifest" "vscode_namespace_rolebinding" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: vscode-workshop-user
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    subjects:
    - kind: ServiceAccount
      name: ${each.key}-vscode-sa
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: vscode-workshop-user
    EOT
  )

  depends_on = [
    kubernetes_manifest.vscode_sa,
    kubernetes_manifest.vscode_namespace_role,
  ]
}
