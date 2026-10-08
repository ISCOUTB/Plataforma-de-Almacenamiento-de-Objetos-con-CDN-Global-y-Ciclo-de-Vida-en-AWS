# scope CLOUDFRONT solo se puede crear en us-east-1 (ya estamos ahi)
resource "aws_wafv2_web_acl" "cdn" {
  name  = "${var.project}-cdn-${var.environment}"
  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimit"
    priority = 1
    action {
      block {}
    }
    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-ratelimit"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedCommon"
    priority = 10
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-common"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-cdn-acl"
    sampled_requests_enabled   = true
  }
}
