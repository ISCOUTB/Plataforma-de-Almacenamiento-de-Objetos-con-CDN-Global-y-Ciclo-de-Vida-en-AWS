variable "project" {
  description = "Prefijo del proyecto"
  type        = string
  default     = "domusnet"
}

variable "environment" {
  description = "Entorno (prod/staging)"
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "Region principal. Todo en us-east-1 para WAF/ACM/Lambda@Edge"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil AWS CLI a usar (cuenta 130841270595)"
  type        = string
  default     = "DomusnetCol"
}

variable "domain_name" {
  description = "Subdominio servido por CloudFront (delegado desde Cloudflare)"
  type        = string
  default     = "app.domusnet.uk"
}

variable "parent_domain" {
  description = "Dominio padre en Cloudflare (solo informativo, la zona Route53 sera solo para el subdominio si no se delega el apex)"
  type        = string
  default     = "domusnet.uk"
}

variable "create_apex_zone" {
  description = "Si true crea hosted zone del apex. Util para la entrega aunque no sea autoritativa (Cloudflare Registrar bloquea NS). Si false, solo valida con CNAME manual."
  type        = bool
  default     = true
}

variable "price_class" {
  description = "Price class de CloudFront"
  type        = string
  default     = "PriceClass_100"
}
