output "cloudfront_domain" {
  value       = module.cloudfront.distribution_domain_name
  description = "Dominio *.cloudfront.net para probar antes del DNS"
}

output "app_url" {
  value       = "https://${var.domain_name}"
  description = "URL final una vez delegado el subdominio"
}

output "route53_nameservers" {
  value       = module.route53.nameservers
  description = "NS a crear en Cloudflare como registros NS para 'app'"
}

output "route53_zone_id" {
  value = module.route53.zone_id
}

output "acm_validation_records" {
  value       = module.acm.validation_records
  description = "Si NO delegas, crea estos CNAME manualmente en Cloudflare (DNS only)"
  sensitive   = false
}

output "assets_bucket" {
  value = module.s3.assets_bucket
}

output "uploads_bucket" {
  value = module.s3.uploads_bucket
}

output "logs_bucket" {
  value = module.s3.logs_bucket
}
