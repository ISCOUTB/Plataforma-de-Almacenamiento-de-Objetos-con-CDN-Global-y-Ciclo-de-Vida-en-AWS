provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Crea los 4 registros NS en Cloudflare bajo el subdominio (app.domusnet.uk)
# apuntando a los nameservers que AWS Route 53 asignó a la zona delegada.
resource "cloudflare_record" "ns_delegation" {
  count = 4

  zone_id = var.cloudflare_zone_id
  name    = var.subdomain_name
  content = var.nameservers[count.index]
  type    = "NS"
  ttl     = 1
}
