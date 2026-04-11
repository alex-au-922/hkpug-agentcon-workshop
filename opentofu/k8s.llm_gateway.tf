resource "kubernetes_manifest" "llm_gateway_sa" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: llm-gateway-sa
      namespace: ${kubernetes_namespace_v1.workshop_shared.metadata[0].name}
      annotations:
        iam.gke.io/gcp-service-account: ${google_service_account.shared_llm_gateway_sa.email}
    EOT
  )
}

resource "kubernetes_config_map_v1" "llm_gateway_config" {
  provider = kubernetes

  metadata {
    name      = "llm-gateway-config"
    namespace = kubernetes_namespace_v1.workshop_shared.metadata[0].name
  }

  data = {
    "config.yaml" = <<-EOF
      model_list:
        - model_name: workshop-gemini
          litellm_params:
            model: vertex_ai/gemini-3.1-flash-lite-preview
            vertex_project: ${data.google_client_config.provider.project}
            vertex_location: global
      litellm_settings:
        drop_params: true
      EOF
  }
}

resource "kubernetes_manifest" "llm_gateway_deployment" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: llm-gateway
      namespace: ${kubernetes_namespace_v1.workshop_shared.metadata[0].name}
    spec:
      replicas: 4
      selector:
        matchLabels:
          app: llm-gateway
      template:
        metadata:
          labels:
            app: llm-gateway
        spec:
          serviceAccountName: llm-gateway-sa
          nodeSelector:
            usage: shared
          affinity:
            podAntiAffinity:
              preferredDuringSchedulingIgnoredDuringExecution:
              - weight: 100
                podAffinityTerm:
                  labelSelector:
                    matchLabels:
                      app: llm-gateway
                  topologyKey: kubernetes.io/hostname
              - weight: 90
                podAffinityTerm:
                  labelSelector:
                    matchLabels:
                      app: llm-gateway
                  topologyKey: topology.kubernetes.io/zone
          containers:
          - name: litellm
            image: docker.litellm.ai/berriai/litellm:main-stable
            args:
            - --config
            - /app/config.yaml
            - --port
            - "4000"
            - --num_workers
            - "2"
            env:
            - name: NO_DOCS
              value: "True"
            - name: NO_REDOC
              value: "True"
            ports:
            - containerPort: 4000
              name: http
            readinessProbe:
              httpGet:
                path: /health/readiness
                port: 4000
              initialDelaySeconds: 20
              periodSeconds: 10
            livenessProbe:
              httpGet:
                path: /health/liveliness
                port: 4000
              initialDelaySeconds: 30
              periodSeconds: 15
            volumeMounts:
            - name: config-volume
              mountPath: /app/config.yaml
              subPath: config.yaml
            resources:
              requests:
                cpu: 500m
                memory: 1Gi
              limits:
                memory: 2Gi
          volumes:
          - name: config-volume
            configMap:
              name: ${kubernetes_config_map_v1.llm_gateway_config.metadata[0].name}
    EOT
  )

  depends_on = [
    kubernetes_manifest.llm_gateway_sa,
    google_project_iam_member.shared_llm_gateway_vertex_ai_user,
    google_service_account_iam_member.shared_llm_gateway_workload_identity_role,
  ]
}

resource "kubernetes_manifest" "llm_gateway_service" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: v1
    kind: Service
    metadata:
      name: llm-gateway
      namespace: ${kubernetes_namespace_v1.workshop_shared.metadata[0].name}
    spec:
      type: ClusterIP
      selector:
        app: llm-gateway
      ports:
      - name: http
        port: 4000
        targetPort: 4000
        protocol: TCP
    EOT
  )

  depends_on = [
    kubernetes_manifest.llm_gateway_deployment,
  ]
}

resource "kubernetes_manifest" "llm_gateway_pdb" {
  provider = kubernetes
  manifest = yamldecode(
    <<EOT
    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: llm-gateway
      namespace: ${kubernetes_namespace_v1.workshop_shared.metadata[0].name}
    spec:
      minAvailable: 1
      selector:
        matchLabels:
          app: llm-gateway
    EOT
  )

  depends_on = [
    kubernetes_manifest.llm_gateway_deployment,
  ]
}
