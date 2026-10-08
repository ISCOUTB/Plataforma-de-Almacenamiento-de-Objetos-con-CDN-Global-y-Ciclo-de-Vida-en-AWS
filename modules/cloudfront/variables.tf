variable "project" { type = string }
variable "environment" { type = string }
variable "domain_name" { type = string }
variable "acm_certificate_arn" { type = string }
variable "assets_bucket_name" { type = string }
variable "assets_bucket_arn" { type = string }
variable "assets_regional_domain" { type = string }
variable "logs_bucket_domain" { type = string }
variable "waf_web_acl_arn" { type = string }
variable "lambda_edge_qualified_arn" { type = string }
variable "price_class" {
  type    = string
  default = "PriceClass_100"
}
