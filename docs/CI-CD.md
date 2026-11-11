# CI/CD y despliegue de DOMUSNET

Este documento describe lo configurado en los tres workflows de GitHub Actions. Que exista código de despliegue no confirma que los recursos estén actualmente desplegados o que los workflows hayan terminado con éxito en AWS.

## Workflows

### `terraform.yml`

- Se ejecuta en pull requests hacia `master`, pushes a `master` cuando cambian Terraform, tfvars, módulos o workflows, y por `workflow_dispatch`.
- El job `validate` ejecuta `terraform fmt -check -recursive`, `terraform init -backend=false -input=false` y `terraform validate -no-color`.
- El job `deploy` solo se ejecuta en un push a `master` y, tras la validación, asume el rol indicado por `AWS_TERRAFORM_ROLE_ARN`, inicializa el backend remoto, crea un plan y lo aplica automáticamente.
- Un `workflow_dispatch` de Terraform ejecuta la validación, pero no aplica: el job `deploy` exige que el evento sea `push` a `master`.
- **Importante:** el workflow aplica cambios en AWS sin una aprobación manual configurada en el YAML. Protege `master` y configura GitHub Environments/aprobaciones antes de habilitar este flujo en una cuenta real.

### `deploy-static.yml`

- Se ejecuta en push a `master` con cambios en `app/**` o mediante `workflow_dispatch`; el job solo despliega cuando la ejecución manual selecciona `master`.
- Asume `AWS_DEPLOY_ROLE_ARN` con OIDC, inicializa Terraform con el backend remoto y lee los outputs `assets_bucket` y `cloudfront_distribution_id`.
- Sincroniza `app/` al bucket de activos usando `aws s3 sync --delete` e invalida `/*` en CloudFront.
- `--delete` elimina del bucket los objetos que ya no están en `app/`; revisar cambios y permisos antes de ejecutarlo.

### `security-checkov.yml`

- Se ejecuta en pull requests hacia `master`, pushes a `master` cuando cambian los archivos Terraform/tfvars o workflows, y mediante `workflow_dispatch`.
- Instala exactamente `checkov==3.4.3` con pip, analiza Terraform y genera `results.sarif`; el resultado se sube con `github/codeql-action/upload-sarif`.
- La instalación fijada evita que una nueva versión de Checkov cambie inesperadamente el análisis.
- El comando de análisis termina con `|| true` y el paso tiene `continue-on-error: true`; por ello, un fallo de Checkov no bloquea actualmente el workflow. El upload de SARIF también depende de que se haya generado el archivo.

## Secrets y valores de configuración

Configurar en GitHub > Settings > Secrets and variables > Actions:

| Secret | Uso |
|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | ARN del rol OIDC que usa el workflow Terraform para acceder al backend y administrar los recursos definidos por Terraform. |
| `AWS_DEPLOY_ROLE_ARN` | ARN del rol OIDC que usa el workflow del sitio para leer el estado/outputs y publicar en S3 e invalidar CloudFront. |
| `CLOUDFLARE_API_TOKEN` | Token inyectado como `TF_VAR_cloudflare_api_token`; necesita permiso para administrar los registros DNS de la zona indicada. |

`cloudflare_zone_id`, `cloudflare_zone_name`, `cloudflare_subdomain`, `domain_name` y otros valores no secretos están en `terraform.tfvars`/`variables.tf`. No copiar tokens, claves de acceso AWS ni credenciales locales a esos archivos.

## OIDC e IAM

Los dos workflows de AWS declaran `id-token: write` y usan `aws-actions/configure-aws-credentials` con `role-to-assume`. En AWS, crear el proveedor OIDC de GitHub (`token.actions.githubusercontent.com`) y una trust policy para el audience `sts.amazonaws.com` y el repositorio/branch exactos. Para este proyecto, verificar el nombre efectivo de `GITHUB_REPOSITORY` antes de fijar `sub`; restringir el rol de despliegue a `refs/heads/master` y no permitir forks.

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
