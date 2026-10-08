# Zona del SUBDOMINIO (esta es la funcional con Cloudflare Registrar bloqueado).
# En Cloudflare: DNS -> Add record -> Type NS, Name "app", valores = nameservers de esta zona.
# Proxy OFF no aplica a NS. El trafico de app.domusnet.uk pasa a ser autoritativo aqui.
resource "aws_route53_zone" "subdomain" {
  name    = var.domain_name
  comment = "DOMUSNET: zona delegada para ${var.domain_name} (NS desde Cloudflare)"
}

# Zona del apex solo documental/academica (no sera autoritativa porque
# Cloudflare Registrar no permite cambiar NS del apex). Cumple el diagrama de la entrega 1.
resource "aws_route53_zone" "apex" {
  count   = var.create_apex_zone ? 1 : 0
  name    = var.parent_domain
  comment = "DOMUSNET: zona apex documental (Cloudflare sigue autoritativo)"
}
