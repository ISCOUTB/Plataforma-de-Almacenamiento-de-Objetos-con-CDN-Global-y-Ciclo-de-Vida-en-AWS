project     = "domusnet"
environment = "prod"
aws_region  = "us-east-1"

domain_name      = "app.domusnet.uk"
parent_domain    = "domusnet.uk"
create_apex_zone = true
price_class      = "PriceClass_100"

cloudflare_zone_id   = "d4c2e91d0bdd3fa9f4f101c8e489f53f"   # ID de la zona domusnet.uk en Cloudflare
cloudflare_zone_name = "domusnet.uk"
cloudflare_subdomain = "app"
