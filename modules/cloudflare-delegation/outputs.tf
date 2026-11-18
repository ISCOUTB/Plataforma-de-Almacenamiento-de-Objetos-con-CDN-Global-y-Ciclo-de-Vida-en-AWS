output "cloudflare_record_ids" {
  value     = cloudflare_record.ns_delegation[*].id
  description = "IDs de los registros NS creados en Cloudflare"
}
