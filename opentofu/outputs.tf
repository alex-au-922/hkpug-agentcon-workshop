output "tenant_infos" {
  value = jsonencode([
    for tenant in local.all_tenant_namespaces : {
      namespace = tenant
      link      = "${tenant}.agentcon-workshop.python.hk"
      password  = nonsensitive(random_password.tenant_namespaces_vscode[tenant].result)
    }
  ])
}
