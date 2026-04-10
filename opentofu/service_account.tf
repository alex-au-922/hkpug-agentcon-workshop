resource "google_service_account" "shared_llm_gateway_sa" {
  account_id   = "${var.stack_prefix}-llm-${var.env}"
  display_name = "${var.stack_prefix} shared llm gateway ${var.env}"
}

resource "google_project_iam_member" "shared_llm_gateway_vertex_ai_user" {
  project = data.google_client_config.provider.project
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.shared_llm_gateway_sa.email}"
}

resource "google_service_account_iam_member" "shared_llm_gateway_workload_identity_role" {
  service_account_id = google_service_account.shared_llm_gateway_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${data.google_client_config.provider.project}.svc.id.goog[workshop-system/llm-gateway-sa]"
}
