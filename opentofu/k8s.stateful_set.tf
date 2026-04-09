resource "kubernetes_manifest" "vscode_statefulset" {
  for_each = toset(local.tenant_namespaces)
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: vscode 
      namespace: ${kubernetes_namespace_v1.tenant[each.key].metadata[0].name}
    spec:
      serviceName: vscode
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
          shareProcessNamespace: true
          initContainers:
          - name: fix-permissions
            image: busybox:latest
            command: ["sh", "-c", "chmod -R 777 /home/coder"]
            volumeMounts:
              - name: vscode-storage
                mountPath: /home/coder
          containers:
            - name: vscode
              image: ${docker_registry_image.vscode.name}
              volumeMounts:
                - name: vscode-storage
                  mountPath: /home/coder
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
      volumeClaimTemplates:
        - metadata:
            name: vscode-storage
          spec:
            accessModes: [ "ReadWriteOnce" ]
            resources:
              requests:
                storage: ${var.tenant_config.storage}
            storageClassName: persistent-storage 
    EOT
  )
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
    HASH=$(docker run --rm httpd:2.4-alpine htpasswd -nbB "$USERNAME" "$PASSWORD" | cut -d ":" -f 2)
    echo "{\"hash\": \"$HASH\"}"
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