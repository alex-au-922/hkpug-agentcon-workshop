resource "google_certificate_manager_certificate_map" "wildcard" {
  name = "${var.stack_prefix}-cert-map-${var.env}"
}

resource "google_certificate_manager_certificate_map_entry" "wildcard" {
  name         = "${var.stack_prefix}-cert-map-entry-${var.env}"
  map          = google_certificate_manager_certificate_map.wildcard.name
  certificates = [google_certificate_manager_certificate.wildcard.id]
  matcher      = "PRIMARY"
}

resource "google_certificate_manager_certificate" "wildcard" {
  name  = "${var.stack_prefix}-domain-${var.env}"
  scope = "DEFAULT"
  managed {
    domains = [
      "*.${var.domain_config.second_level_domain}" # issue wildcard domain cert
    ]
    dns_authorizations = [
      google_certificate_manager_dns_authorization.wildcard.id,
    ]
  }
}

resource "google_certificate_manager_dns_authorization" "wildcard" {
  name   = "${var.stack_prefix}-domain-${var.env}"
  domain = var.domain_config.second_level_domain # the second level domain can use to issue wildcard
  type   = "PER_PROJECT_RECORD"
}
