terraform {
  backend "s3" {
    bucket       = "domusnet-tfstate-130841270595"
    key          = "domusnet/prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
# Las credenciales se obtienen de la cadena estandar de AWS (variables de entorno,
# rol IAM, etc.). El bucket remoto debe existir y ser accesible para cada integrante.
