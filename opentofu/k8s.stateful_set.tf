resource "kubernetes_persistent_volume_claim_v1" "vscode_workspace" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes

  metadata {
    name      = "vscode-workspace"
    namespace = kubernetes_namespace_v1.tenant[each.key].metadata[0].name
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "persistent-storage"

    resources {
      requests = {
        storage = var.tenant_config.storage
      }
    }
  }
}

resource "kubernetes_manifest" "vscode_deployment" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  computed_fields = ["metadata.annotations"]

  field_manager {
    force_conflicts = true
  }

  manifest = yamldecode(
    <<EOT
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: vscode
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: vscode
      template:
        metadata:
          labels:
            app: vscode
        spec:
          serviceAccountName: ${kubernetes_manifest.vscode_sa[each.key].object.metadata.name}
          nodeSelector:
            usage: workshop
          shareProcessNamespace: true
          initContainers:
          - name: seed-home
            image: ${docker_registry_image.vscode.name}
            securityContext:
              runAsUser: 0
            command:
            - sh
            - -c
            - |
              mkdir -p /home/coder /home/coder/.zsh /home/coder/.vscode /home/coder/.vscode-data/User /home/coder/.vscode-data/extensions /home/coder/.vscode-server/extensions /home/coder/.local/share
              if [ ! -f /home/coder/.zshrc ]; then cp /opt/workshop-home/.zshrc /home/coder/.zshrc; fi
              cp /opt/workshop-home/.vscode-data/User/settings.json /home/coder/.vscode-data/User/settings.json
              if [ ! -d /home/coder/.zsh/plugins ]; then cp -a /opt/workshop-home/.zsh/plugins /home/coder/.zsh/; fi
              cp -a /opt/workshop-home/.vscode/extensions/. /home/coder/.vscode/extensions/
              cp -a /opt/workshop-home/.vscode/extensions/. /home/coder/.vscode-data/extensions/
              cp -a /opt/workshop-home/.vscode/extensions/. /home/coder/.vscode-server/extensions/
              if [ ! -d /home/coder/.local/share/jupyter ]; then mkdir -p /home/coder/.local/share && cp -a /opt/workshop-home/.local/share/jupyter /home/coder/.local/share/; fi
              rm -rf /home/coder/workspace/.venv
              if [ ! -f /home/coder/workspace/requirements.txt ]; then cp -a /opt/workshop-seed/workspace/. /home/coder/workspace/; fi
              rm -f /home/coder/.p10k.zsh
              chown 1000:1000 /home/coder
              chown -R 1000:1000 /home/coder/.zsh /home/coder/.vscode /home/coder/.vscode-data /home/coder/.vscode-server /home/coder/.local /home/coder/workspace /home/coder/.zshrc
              chmod 755 /home/coder
              chmod -R u+rwX,go+rX /home/coder/.zsh /home/coder/.vscode /home/coder/.vscode-data /home/coder/.vscode-server /home/coder/.local /home/coder/workspace
              chmod -R go-w /home/coder/.zsh /home/coder/.vscode /home/coder/.vscode-data /home/coder/.vscode-server /home/coder/.local /home/coder/workspace
              chmod 644 /home/coder/.zshrc
            volumeMounts:
              - name: vscode-home
                mountPath: /home/coder
              - name: vscode-workspace
                mountPath: /home/coder/workspace
          containers:
            - name: vscode
              image: ${docker_registry_image.vscode.name}
              volumeMounts:
                - name: vscode-home
                  mountPath: /home/coder
                - name: vscode-workspace
                  mountPath: /home/coder/workspace
              ports:
                - containerPort: 8000
                  name: vscode
                - containerPort: 8080
                  name: user-http
              resources:
                requests:
                  memory: 5Gi
                limits:
                  memory: 5Gi
            - name: nginx-auth-proxy
              image: nginx:alpine
              ports:
                - containerPort: 80
                  name: http
              volumeMounts:
                - name: nginx-config
                  mountPath: /etc/nginx/conf.d
                - name: basic-auth-credentials
                  mountPath: /etc/nginx/.htpasswd
                  subPath: auth
              resources:
                requests:
                  cpu: 100m
                  memory: 128Mi
                limits:
                  memory: 128Mi
          volumes:
            - name: nginx-config
              configMap:
                name: ${kubernetes_config_map_v1.nginx_config[each.key].metadata[0].name} 
            - name: basic-auth-credentials
              secret:
                secretName: ${kubernetes_secret.basic_auth_credentials[each.key].metadata[0].name}
            - name: vscode-home
              emptyDir: {}
            - name: vscode-workspace
              persistentVolumeClaim:
                claimName: ${kubernetes_persistent_volume_claim_v1.vscode_workspace[each.key].metadata[0].name}
    EOT
  )

  depends_on = [
    kubernetes_persistent_volume_claim_v1.vscode_workspace,
  ]
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
