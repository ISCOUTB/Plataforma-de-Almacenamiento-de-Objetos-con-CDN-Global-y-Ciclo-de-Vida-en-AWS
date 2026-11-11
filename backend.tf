terraform {
  backend "s3" {
    bucket       = "domusnet-tfstate-130841270595"
    key          = "domusnet/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
