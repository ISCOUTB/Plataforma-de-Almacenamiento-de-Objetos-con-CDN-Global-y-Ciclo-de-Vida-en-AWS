output "cloudflare_record_ids" {
  value = [for r in cloudflare_record.ns_delegation : r.id]
  description = "IDs de los registros NS creados en Cloudflare"
}
