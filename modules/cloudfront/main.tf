resource "aws_cloudfront_origin_access_control" "assets" {
  name                              = "${var.project}-assets-${var.environment}"
  description                       = "OAC para ${var.assets_bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = var.price_class
  web_acl_id          = var.waf_web_acl_arn

  origin {
    domain_name              = var.assets_regional_domain
    origin_id                = "s3-assets"
    origin_access_control_id = aws_cloudfront_origin_access_control.assets.id
  }

  # Assets cacheados 24h
  default_cache_behavior {
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 86400

    lambda_function_association {
      event_type   = "viewer-response"
      lambda_arn   = var.lambda_edge_qualified_arn
      include_body = false
    }
  }

  # index.html sin cache (para deploys inmediatos)
  ordered_cache_behavior {
    path_pattern           = "/index.html"
    target_origin_id       = "s3-assets"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0

    lambda_function_association {
      event_type   = "viewer-response"
      lambda_arn   = var.lambda_edge_qualified_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  logging_config {
    bucket          = var.logs_bucket_domain
    prefix          = "cloudfront/"
    include_cookies = false
  }

  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/error.html"
  }
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/error.html"
  }
}

# Bucket privado: solo CloudFront via OAC puede leer
resource "aws_s3_bucket_policy" "assets" {
  bucket = var.assets_bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${var.assets_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}
