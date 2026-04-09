data "google_project" "this" {
}

resource "google_project_service" "this" {
  for_each = toset(var.enabled_services)
  provider = google
  project  = data.google_project.this.id
  service  = "${each.key}.googleapis.com"

  disable_on_destroy = false
}
