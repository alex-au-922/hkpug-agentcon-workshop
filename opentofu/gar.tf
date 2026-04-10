resource "google_artifact_registry_repository" "this" {
  location      = var.region
  repository_id = "${var.stack_prefix}-docker-repo-${var.env}"
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "this" {
  project    = google_artifact_registry_repository.this.project
  location   = google_artifact_registry_repository.this.location
  repository = google_artifact_registry_repository.this.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke.email}"
}

resource "docker_image" "vscode" {
  name = "${var.region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.this.repository_id}/vscode:sha256-${local.vscode_image_hash}"

  depends_on = [
    terraform_data.vscode_extension_cache,
  ]

  build {
    context    = "${path.module}/.."
    dockerfile = "opentofu/manifests/Dockerfile"
    platform   = "linux/amd64"
    build_args = {
      hash = local.vscode_image_hash
    }
  }
}

resource "docker_registry_image" "vscode" {
  name          = docker_image.vscode.name
  keep_remotely = false

  depends_on = [
    google_artifact_registry_repository.this,
    docker_image.vscode
  ]
}
