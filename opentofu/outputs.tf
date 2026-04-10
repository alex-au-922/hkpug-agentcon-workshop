output "tenant_infos" {
  value = [
    for tenant in local.all_tenant_namespaces : {
      namespace       = tenant
      vscode_password = nonsensitive(random_password.tenant_namespaces_vscode[tenant].result)
    }
  ]
}
