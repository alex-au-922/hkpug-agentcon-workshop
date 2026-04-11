locals {
  all_tenant_namespaces = [for i, tenant in null_resource.tenant_namespaces : "user-${format("%02d", i)}"]
  tenant_namespaces     = [for i, tenant in slice(null_resource.tenant_namespaces, 0, var.tenant_config.curr_tenant_num) : "user-${format("%02d", i)}"]
  vscode_extensions = {
    for ext in var.vscode_extensions : ext.id => merge(ext, {
      output = "manifests/extensions/cache/${ext.filename}"
    })
  }

  vscode_src_files = setsubtract(
    toset(fileset("${path.module}/../src", "**")),
    toset(concat(
      tolist(fileset("${path.module}/../src", ".venv/**")),
      tolist(fileset("${path.module}/../src", "**/__pycache__/**")),
      tolist(fileset("${path.module}/../src", "**/.ipynb_checkpoints/**"))
    ))
  )

  vscode_build_files = concat(
    ["manifests/Dockerfile", "../.dockerignore"],
    [for file in sort(tolist(fileset("${path.module}/manifests/home", "**"))) : "manifests/home/${file}"],
    [for file in sort(tolist(local.vscode_src_files)) : "../src/${file}"]
  )
}
