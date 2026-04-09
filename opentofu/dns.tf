resource "cloudflare_dns_record" "domain_verification" {
  zone_id = var.domain_config.zone_id
  name    = google_certificate_manager_dns_authorization.wildcard.dns_resource_record.0.name
  type    = google_certificate_manager_dns_authorization.wildcard.dns_resource_record.0.type
  content = google_certificate_manager_dns_authorization.wildcard.dns_resource_record.0.data
  proxied = false
  ttl     = 60
}

resource "cloudflare_dns_record" "wildcard_domain" {
  zone_id = var.domain_config.zone_id
  name    = "*.${var.domain_config.second_level_domain}"
  type    = "A"
  content = google_compute_global_address.load_balancer.address
  proxied = false
  ttl     = 60
}
