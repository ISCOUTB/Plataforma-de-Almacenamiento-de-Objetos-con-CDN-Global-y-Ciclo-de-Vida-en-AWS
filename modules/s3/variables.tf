variable "project" { type = string }
variable "environment" { type = string }
variable "bucket_suffix" {
  description = "Sufijo para unicidad global (account id)"
  type        = string
}
