# Handoff para configuración AWS de DOMUSNET

## Objetivo y límites

Preparar la cuenta y GitHub Actions para que el equipo pueda validar Terraform, aplicar infraestructura desde `main` y publicar el sitio estático. El código define esos flujos; este handoff no confirma que se hayan configurado AWS, OIDC, secrets o recursos. No almacenar credenciales en el repositorio.

## 1. Confirmar cuenta y región

Antes de crear permisos, acordar con el equipo:

- AWS account ID y cuenta/ambiente objetivo.
- Región principal `us-east-1` (CloudFront, WAF scope `CLOUDFRONT`, ACM para CloudFront y Lambda@Edge usan esa región según el código).
- Repositorio GitHub efectivo y rama `main`; cotejarlo con `GITHUB_REPOSITORY` y no confiar solo en el URL del README.
- Owner del dominio/zona Cloudflare y quién puede crear/cambiar sus registros.

## 2. Preparar el backend S3 (bootstrap separado)

`backend.tf` apunta a:

- Bucket: `domusnet-tfstate-130841270595`
- Key: `domusnet/prod/terraform.tfstate`
- Región: `us-east-1`
- Cifrado: habilitado por configuración de backend
- Locking: `use_lockfile = true`

El bucket debe existir antes del primer `terraform init` remoto; este root no declara el bucket del backend. Configurarlo de forma segura fuera del propio state que alojará: bloquear acceso público, cifrar, habilitar versionado/recuperación, restringir acceso por IAM y conservar el objeto de lock. Confirmar compatibilidad de `use_lockfile` con la versión de Terraform utilizada y permitir las operaciones del lock al rol que las necesite. No borrar el bucket ni el state para “reiniciar” el despliegue.

El job de validación usa `terraform init -backend=false`, pero los jobs Terraform y de publicación usan el backend remoto. El rol de publicación necesita acceso de lectura al state para `terraform output`; revisar también si el flujo de init/output requiere operaciones de locking.

## 3. Configurar OIDC y los roles

Configurar en AWS el proveedor OIDC `token.actions.githubusercontent.com` con audience `sts.amazonaws.com`. Crear trust policies separadas para:

1. Rol Terraform, consumido por `.github/workflows/terraform.yml`.
2. Rol de publicación, consumido por `.github/workflows/deploy-static.yml`.

En cada trust policy:

- Restringir `sub` al repositorio exacto y a `refs/heads/main` para estos workflows.
- No habilitar `pull_request` ni forks para asumir roles con permisos AWS.
- Confirmar que el workflow tiene `permissions: id-token: write`.
- Aplicar mínimo privilegio y revisar la policy contra el plan y las acciones realmente requeridas.

### Alcance IAM a considerar

- **Rol Terraform:** acceso limitado al state/lock del backend y permisos para gestionar únicamente los recursos declarados por los módulos: S3, CloudFront, ACM, Route 53, WAF, Lambda@Edge y recursos/roles IAM asociados. Añadir permisos de lectura/descubrimiento necesarios para plan. Las acciones y ARNs exactos dependen del estado y del plan; revisarlos antes de habilitar `apply`.
- **Rol publicación:** `s3:ListBucket` sobre el bucket de activos; `s3:PutObject` y `s3:DeleteObject` sobre sus objetos (el workflow usa `sync --delete`); `cloudfront:CreateInvalidation` sobre la distribución concreta; y permisos mínimos para leer el objeto de Terraform state y, si aplica, operar su lock.
- **Cloudflare:** Terraform usa el provider de Cloudflare y el token separado; esos permisos no se sustituyen con IAM AWS.

No copiar una policy genérica de administrador. Validar permisos con un plan y una ejecución controlada, y ajustar denegaciones faltantes de forma acotada.

## 4. Configurar los secrets de GitHub

En Settings > Secrets and variables > Actions:

| Nombre exacto | Contenido/uso |
|---|---|
| `AWS_TERRAFORM_ROLE_ARN` | ARN del rol Terraform. |
| `AWS_DEPLOY_ROLE_ARN` | ARN del rol de publicación. |
| `CLOUDFLARE_API_TOKEN` | Token de API DNS, usado como `TF_VAR_cloudflare_api_token`. |

El ID y nombre de zona, dominio, proyecto, ambiente y clase de precio están en `terraform.tfvars` y `variables.tf`; no son esos secrets. Rotar inmediatamente cualquier token publicado accidentalmente.

## 5. Verificar backend, variables y outputs

Antes de ejecución:

- Confirmar coincidencia entre el bucket backend configurado y el recurso real.
- Confirmar que `terraform.tfvars` corresponde a la cuenta/dominio acordados.
- Confirmar que `CLOUDFLARE_API_TOKEN` tiene permisos en el zone ID configurado.
- Confirmar que existen los outputs root `assets_bucket` y `cloudfront_distribution_id`, usados por el workflow estático.
- El nombre del bucket de assets se genera con `project`, `environment` y AWS account ID; no asumir que el nombre de ejemplo es el nombre existente.

## 6. Pruebas recomendadas y control del despliegue

1. Ejecutar validaciones sin backend: `terraform fmt -check -recursive`, `terraform init -backend=false -input=false`, `terraform validate`, `actionlint .github/workflows/*.yml`.
2. Verificar OIDC con un job de prueba de identidad que no modifique recursos, antes de habilitar `apply`.
3. Probar `terraform plan` contra el backend y revisar cada cambio, cuenta, región, DNS, costos y reemplazos.
4. En entorno/cuenta aprobados, ejecutar la aplicación con revisión del plan y autorización del responsable. El workflow actual realiza `terraform apply -auto-approve` tras un push a `main`; establecer branch protection y GitHub Environment con aprobación si la política del equipo lo exige.
5. Probar publicación controlada a S3 y la invalidación CloudFront. Tener presente que `aws s3 sync --delete` elimina objetos del bucket que no estén en `app/`.
6. Verificar resultado en AWS: recursos, estado Terraform, logs del workflow, DNS/delegación, validación ACM, URL HTTPS, contenido, cabeceras y CloudFront invalidation.

No ejecutar `terraform destroy` como parte de estas pruebas. El estado final debe registrarse en [ESTADO-PROYECTO.md](./ESTADO-PROYECTO.md) con fecha, cuenta/región, commit y evidencia. El estado desplegado permanece **pendiente de confirmación** hasta que esas comprobaciones se realicen.
