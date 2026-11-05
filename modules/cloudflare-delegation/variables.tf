variable "cloudflare_api_token" {
  description = "API Token de Cloudflare con permiso DNS:Edit sobre la zona raíz"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "ID de la zona domusnet.uk en Cloudflare (se ve en la URL del dashboard)"
  type        = string
}

variable "cloudflare_zone_name" {
  description = "Nombre de la zona raíz en Cloudflare"
  type        = string
  default     = "domusnet.uk"
}

variable "subdomain_name" {
  description = "Nombre del subdominio "
  type        = string
  default     = "app"
}

variable "nameservers" {
  description = "Lista de 4 nameservers de la zona Route 53 de app.domusnet.uk"
  type        = list(string)
}
