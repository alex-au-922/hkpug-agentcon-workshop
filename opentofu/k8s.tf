data "kubernetes_namespace_v1" "kube_system" {
  provider = kubernetes
  metadata {
    name = "kube-system"
  }
}

# placeholder for iterator
resource "null_resource" "tenant_namespaces" {
  count = var.tenant_config.max_tenant_num
} 

resource "random_password" "tenant_namespaces_vscode" {
  for_each = toset(local.all_tenant_namespaces)
  length   = var.tenant_config.vscode_password_length
  numeric  = true
  lower    = false
  upper    = false
  special  = false
}

resource "kubernetes_namespace_v1" "tenant" {
  for_each = toset(local.all_tenant_namespaces)
  provider = kubernetes
  metadata {
    name = each.value
    labels = {
      role = "tenant"
    }
  }
}

resource "kubernetes_manifest" "storageclass" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: persistent-storage 
    provisioner: pd.csi.storage.gke.io
    reclaimPolicy: Retain
    volumeBindingMode: Immediate
    EOT
  )
}
