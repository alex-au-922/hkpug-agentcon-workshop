resource "kubernetes_deployment_v1" "vscode_deployment" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes

  metadata {
    name      = "vscode"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
    labels = {
      app = "vscode"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vscode"
      }
    }

    template {
      metadata {
        labels = {
          app = "vscode"
        }
      }

      spec {
        service_account_name    = kubernetes_manifest.vscode_sa[each.key].object.metadata.name
        share_process_namespace = true
        node_selector = {
          usage = "workshop"
        }

        container {
          name  = "vscode"
          image = "${split(":", docker_registry_image.vscode.name)[0]}@${docker_registry_image.vscode.sha256_digest}"

          port {
            container_port = 8000
            name           = "vscode"
          }

          port {
            container_port = 8080
            name           = "user-http"
          }

          resources {
            requests = {
              memory = "6Gi"
            }
            limits = {
              memory = "6Gi"
            }
          }
        }

        container {
          name  = "nginx-auth-proxy"
          image = "nginx:alpine"

          port {
            container_port = 80
            name           = "http"
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d"
          }

          volume_mount {
            name       = "basic-auth-credentials"
            mount_path = "/etc/nginx/.htpasswd"
            sub_path   = "auth"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              memory = "128Mi"
            }
          }
        }

        volume {
          name = "nginx-config"
          config_map {
            name = kubernetes_config_map_v1.nginx_config[each.key].metadata[0].name
          }
        }

        volume {
          name = "basic-auth-credentials"
          secret {
            secret_name = kubernetes_secret.basic_auth_credentials[each.key].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map_v1" "nginx_config" {
  for_each = toset(local.tenant_namespaces)
  metadata {
    name      = "nginx-config"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  data = {
    "default.conf" = <<-EOF
      server {
        listen 80;
        
        # Authentication for VS Code access
        auth_basic "VS Code Access";
        auth_basic_user_file /etc/nginx/.htpasswd;
        
        # VS Code web interface
        location / {
          proxy_pass http://localhost:8000;
          proxy_http_version 1.1;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
        }
      }
    EOF
  }
}

data "external" "htpasswd_hash" {
  for_each = toset(local.tenant_namespaces)

  program = ["bash", "-c", <<EOT
    PASSWORD="${random_password.tenant_namespaces_vscode[each.key].result}"
    USERNAME="${each.key}"
    SALT="${substr(sha256(join(":", [each.key, random_password.tenant_namespaces_vscode[each.key].result])), 0, 8)}"
    HASH=$(openssl passwd -apr1 -salt "$SALT" "$PASSWORD")
    printf '{"hash":"%s"}\n' "$HASH"
  EOT
  ]
}

resource "kubernetes_secret" "basic_auth_credentials" {
  for_each = toset(local.tenant_namespaces)

  metadata {
    name      = "basic-auth-credentials"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  data = {
    auth = "${each.key}:${data.external.htpasswd_hash[each.key].result.hash}"
  }

}
