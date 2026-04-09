locals {
  all_tenant_namespaces = [for i, tenant in null_resource.tenant_namespaces : "user-${format("%02d", i)}"]
  tenant_namespaces = [for i, tenant in slice(null_resource.tenant_namespaces, 0, var.tenant_config.curr_tenant_num) : "user-${format("%02d", i)}"]
}
