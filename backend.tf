terraform {
  backend "s3" {
    bucket       = "domusnet-tfstate-130841270595"
    key          = "domusnet/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
    profile      = "DomusnetCol"
  }
}
# Backend en la cuenta 130841270595 (perfil DomusnetCol).
# Requiere que exista el bucket (pendiente: SCP del org bloquea s3:CreateBucket).
# Para re-enganchar cuando exista: terraform init -reconfigure
