# DOMUSNET - Plataforma de almacenamiento con CDN global
# app.domusnet.uk delegado desde Cloudflare -> Route53 -> CloudFront
# Flujo: Cloudflare (solo NS delegacion, proxy OFF) -> Route53 alias ->
#        WAF -> CloudFront + Lambda@Edge viewer-response -> S3 (OAC)

data "aws_caller_identity" "current" {}

locals {
  bucket_suffix = data.aws_caller_identity.current.account_id
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "s3" {
  source = "./modules/s3"

  project       = var.project
  environment   = var.environment
  bucket_suffix = local.bucket_suffix
}

module "route53" {
  source = "./modules/route53"

  domain_name      = var.domain_name
  parent_domain    = var.parent_domain
  create_apex_zone = var.create_apex_zone
}

module "acm" {
  source = "./modules/acm"

  domain_name     = var.domain_name
  parent_domain   = var.parent_domain
  zone_id         = module.route53.zone_id
  validation_fqdn = var.domain_name
}

module "lambda_edge" {
  source = "./modules/lambda-edge"

  project     = var.project
  environment = var.environment
}

module "waf" {
  source = "./modules/waf"

  project     = var.project
  environment = var.environment
}

module "cloudfront" {
  source = "./modules/cloudfront"

  project     = var.project
  environment = var.environment

  domain_name         = var.domain_name
  acm_certificate_arn = module.acm.certificate_arn

  assets_bucket_name        = module.s3.assets_bucket
  assets_bucket_arn         = module.s3.assets_bucket_arn
  assets_regional_domain    = module.s3.assets_regional_domain
  logs_bucket_domain        = module.s3.logs_bucket_domain
  waf_web_acl_arn           = module.waf.web_acl_arn
  lambda_edge_qualified_arn = module.lambda_edge.qualified_arn

  price_class = var.price_class
}

# Alias A -> CloudFront (solo funciona cuando el subdominio esta delegado a esta zona)
resource "aws_route53_record" "app_alias" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_alias_v6" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.distribution_domain_name
    zone_id                = module.cloudfront.distribution_hosted_zone_id
    evaluate_target_health = false
  }
}
