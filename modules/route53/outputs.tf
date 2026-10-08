output "zone_id" {
  value       = aws_route53_zone.subdomain.zone_id
  description = "Zona funcional (delegar 'app' desde Cloudflare con estos NS)"
}
output "nameservers" { value = aws_route53_zone.subdomain.name_servers }
output "apex_zone_id" {
  value       = var.create_apex_zone ? aws_route53_zone.apex[0].zone_id : null
  description = "Zona apex documental"
}
