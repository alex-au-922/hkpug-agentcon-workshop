resource "google_project_iam_member" "vertex_ai_user" {
  for_each = toset(local.tenant_namespaces)
  project  = data.google_client_config.provider.project
  role     = "roles/aiplatform.user"
  member   = "serviceAccount:${google_service_account.workload_identity_user_sa[each.key].email}"
}

resource "google_service_account" "workload_identity_user_sa" {
  for_each   = toset(local.tenant_namespaces)
  account_id = each.key
}

resource "google_service_account_iam_member" "workload_identity_role" {
  for_each           = toset(local.tenant_namespaces)
  service_account_id = google_service_account.workload_identity_user_sa[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${data.google_client_config.provider.project}.svc.id.goog[${each.key}/${kubernetes_manifest.vscode_sa[each.key].object.metadata.name}]"
}