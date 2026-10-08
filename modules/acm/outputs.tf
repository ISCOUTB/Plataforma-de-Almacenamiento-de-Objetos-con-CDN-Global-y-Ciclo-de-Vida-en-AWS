output "certificate_arn" { value = aws_acm_certificate_validation.app.certificate_arn }
output "validation_records" {
  value = {
    for k, r in aws_route53_record.validation : k => {
      name  = r.name
      type  = r.type
      value = join(",", r.records)
    }
  }
}
