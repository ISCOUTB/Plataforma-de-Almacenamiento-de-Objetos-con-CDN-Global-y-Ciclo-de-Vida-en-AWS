# Guía de ejecución de DOMUSNET

## Alcance y estado

Esta guía describe cómo validar el código y, cuando la cuenta y sus permisos estén preparados, cómo ejecutar los workflows configurados. La presencia de Terraform y de workflows no demuestra que la infraestructura esté desplegada. El estado actual de AWS debe confirmarse en la cuenta con credenciales autorizadas.

## Requisitos

- Terraform CLI `>= 1.10.5` (el workflow CI instala `1.10.5`).
- AWS CLI y credenciales locales/SSO para ejecución manual en AWS.
- Cuenta AWS con IAM y servicios necesarios; región `us-east-1`.
- Token Cloudflare con permisos DNS de la zona configurada.
- `actionlint` para validar workflows localmente (opcional, pero recomendado).

## 1. Preparar valores y secretos

Los valores no secretos del entorno productivo están en `terraform.tfvars`: proyecto `domusnet`, ambiente `prod`, región `us-east-1`, dominio `app.domusnet.uk`, zona Cloudflare y `PriceClass_100`. `envs/prod.tfvars` actualmente solo contiene un comentario y no define valores.

No guardar el token de Cloudflare en archivos versionados. En macOS/Linux se puede exportar para Terraform local:

```bash
export TF_VAR_cloudflare_api_token='TOKEN_DE_CLOUDFLARE'
```

Para GitHub Actions, configurar `CLOUDFLARE_API_TOKEN` como secret. Configurar también `AWS_TERRAFORM_ROLE_ARN` y `AWS_DEPLOY_ROLE_ARN` según [ENTREGA-COMPAÑERO-AWS.md](./ENTREGA-COMPAÑERO-AWS.md).

## 2. Validar sin conectarse al backend remoto

Desde la raíz:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
actionlint .github/workflows/*.yml
```

`terraform init -backend=false` inicializa proveedores sin acceder al bucket del estado. `terraform validate` valida la configuración; ninguno de estos comandos despliega recursos. `git diff --check` puede comprobar espacios en cambios cuando se ejecuta dentro de un clon Git.

## 3. Despliegue de infraestructura: operación con efectos en AWS

El workflow `.github/workflows/terraform.yml` contiene un job que, en push a `main`, ejecuta `terraform init`, `terraform plan` y `terraform apply -auto-approve`. No requiere una aprobación manual en la definición actual. Antes de habilitarlo:

1. Preparar el backend S3 definido en `backend.tf`.
2. Configurar OIDC, trust policy, permisos IAM y secrets de GitHub.
3. Confirmar el plan, costos, cuenta/rol y cambios DNS/certificado.
4. Proteger `main` y considerar una aprobación de GitHub Environment.

No se ejecutó `terraform apply` ni `terraform destroy` como parte de esta documentación.

## 4. Publicación de contenido

El workflow `deploy-static.yml` publica `app/` solo en `main`, por push con cambios bajo `app/**` o por ejecución manual seleccionando `main`. Obtiene:

- `terraform output -raw assets_bucket`
- `terraform output -raw cloudfront_distribution_id`

Después hace `aws s3 sync app/ s3://<assets_bucket>/ --delete` e invalida `/*` en la distribución. El código Terraform define estos outputs en `outputs.tf`. La opción `--delete` elimina del bucket cualquier objeto que no esté en el directorio local `app/`; comprobar el contenido y el bucket destino antes de activar el despliegue.

## 5. Seguridad y verificación posterior

`security-checkov.yml` instala `checkov==3.4.3`, examina Terraform y, si genera `results.sarif`, publica el resultado en GitHub Code Scanning. Actualmente el comando permite que fallos de Checkov no fallen el job (`|| true` y `continue-on-error`).

Tras un despliegue autorizado, el responsable de AWS debe comprobar en la cuenta:

- Estado de los recursos Terraform y outputs (bucket, distribución, URL y nameservers).
- Delegación DNS y estado de validación del certificado ACM.
- Acceso a `https://app.domusnet.uk`, contenido publicado y cabeceras HTTP.
- Resultado de los workflows y eventos de CloudTrail.

Estos puntos son verificaciones posteriores propuestas; no se afirma que se hayan ejecutado ni que el despliegue exista actualmente.
