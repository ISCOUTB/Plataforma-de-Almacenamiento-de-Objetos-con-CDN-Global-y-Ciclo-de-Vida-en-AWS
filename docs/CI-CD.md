# CI/CD y despliegue de DOMUSNET

El workflow único `.github/workflows/pipeline.yml` organiza los controles y despliegues en una secuencia. Su configuración no confirma que AWS, Cloudflare o los workflows estén operativos; eso debe comprobarse en la cuenta y en las ejecuciones de GitHub Actions.

## Flujo

El workflow se inicia en cada push a `master`, en pull requests hacia `master` y manualmente con `workflow_dispatch`.

1. **Checkov:** instala `checkov==3.4.3`, analiza Terraform y genera resultados SARIF. Checkov es bloqueante: si falla el análisis, no comienza la validación ni el despliegue.
2. **Validación Terraform:** después de Checkov, ejecuta `terraform fmt -check -recursive`, `terraform init -backend=false -input=false` y `terraform validate`.
3. **Aplicar infraestructura:** solo para pushes a `master` o ejecución manual seleccionando `master`; asume `AWS_TERRAFORM_ROLE_ARN` mediante OIDC, inicializa el backend remoto y ejecuta `terraform plan` seguido de `terraform apply -auto-approve`.
4. **Publicar sitio:** solo comienza si la infraestructura terminó con éxito; asume `AWS_DEPLOY_ROLE_ARN` mediante OIDC, obtiene los outputs de Terraform, sincroniza `app/` con S3 e invalida `/*` en CloudFront.

En un pull request solo corren Checkov y la validación; nunca se asume un rol AWS ni se despliega. Un `workflow_dispatch` en una rama distinta de `master` también se limita a los controles. No hay aprobación manual para `terraform apply`: proteger `master` y configurar un GitHub Environment con aprobación antes de habilitar el despliegue en una cuenta real.

`aws s3 sync --delete` elimina del bucket los objetos que ya no están en `app/`; revisar contenido y destino antes de ejecutar el despliegue.

## Secrets y valores de configuración

Configurar en GitHub > Settings > Secrets and variables > Actions:

| Secret | Uso |
|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | ARN del rol OIDC que usa el workflow Terraform para acceder al backend y administrar los recursos definidos por Terraform. |
| `AWS_DEPLOY_ROLE_ARN` | ARN del rol OIDC que usa el workflow del sitio para leer el estado/outputs y publicar en S3 e invalidar CloudFront. |
| `CLOUDFLARE_API_TOKEN` | Token inyectado como `TF_VAR_cloudflare_api_token`; necesita permiso para administrar los registros DNS de la zona indicada. |

`cloudflare_zone_id`, `cloudflare_zone_name`, `cloudflare_subdomain`, `domain_name` y otros valores no secretos están en `terraform.tfvars`/`variables.tf`. No copiar tokens, claves de acceso AWS ni credenciales locales a esos archivos.

## OIDC e IAM

Los dos jobs de despliegue de AWS declaran `id-token: write` y usan `aws-actions/configure-aws-credentials` con `role-to-assume`. En AWS, crear el proveedor OIDC de GitHub (`token.actions.githubusercontent.com`) y una trust policy para el audience `sts.amazonaws.com` y el repositorio/branch exactos. Para este proyecto, verificar el nombre efectivo de `GITHUB_REPOSITORY` antes de fijar `sub`; restringir el rol de despliegue a `refs/heads/master` y no permitir forks.

Usar dos roles y mínimo privilegio:

- **Terraform:** acceso al objeto de estado en el backend y permisos acotados a los recursos gestionados por este root (S3, CloudFront, ACM, Route 53, WAF, Lambda/IAM asociado y Cloudflare vía API token). El alcance de IAM debe derivarse del plan y las acciones de los módulos; no se incluye aquí una policy universal.
- **Sitio estático:** permisos para leer el estado necesario para `terraform output`, listar el bucket de activos, escribir/eliminar objetos de ese bucket e invalidar la distribución de CloudFront concreta. Restringir recursos por ARN. Considerar permisos de bloqueo del backend S3 si Terraform los requiere para la inicialización/lectura.

No usar access keys de largo plazo en GitHub.

## Backend remoto

`backend.tf` requiere que exista el bucket `domusnet-tfstate-130841270595` en `us-east-1`, con la clave `domusnet/prod/terraform.tfstate`, cifrado y locking S3 mediante `use_lockfile = true`. El backend/bucket se debe preparar antes del primer `terraform init` remoto. Revisar versionado, bloqueo de acceso público, cifrado, recuperación y permisos IAM. El workflow de validación usa intencionalmente `-backend=false`; los jobs de despliegue usan el backend real.

## Validación local

Desde la raíz del proyecto:

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
actionlint .github/workflows/*.yml
```

Estos comandos validan sintaxis/configuración; no aplican cambios en AWS. Para instrucciones paso a paso, consulta [GUIA-EJECUCION.md](./GUIA-EJECUCION.md). Para el handoff de configuración de cuenta y roles, consulta [ENTREGA-COMPAÑERO-AWS.md](./ENTREGA-COMPAÑERO-AWS.md).
