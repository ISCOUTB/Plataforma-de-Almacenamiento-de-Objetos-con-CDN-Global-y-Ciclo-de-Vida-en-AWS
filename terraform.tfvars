project     = "domusnet"
environment = "prod"
aws_region  = "us-east-1"

domain_name      = "app.domusnet.uk"
parent_domain    = "domusnet.uk"
create_apex_zone = true
price_class      = "PriceClass_100"

cloudflare_zone_id   = "f336811c642c1b348126cc00b2352474" # ID de la zona domusnet.uk en Cloudflare
cloudflare_zone_name = "domusnet.uk"
cloudflare_subdomain = "app"
