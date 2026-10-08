variable "domain_name" { type = string }
variable "parent_domain" { type = string }
variable "create_apex_zone" {
  type    = bool
  default = true
}
