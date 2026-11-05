provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = "domusnet"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Todo en us-east-1: CloudFront, WAF (scope CLOUDFRONT), ACM y Lambda@Edge
# exigen us-east-1, asi evitamos provider alias.
