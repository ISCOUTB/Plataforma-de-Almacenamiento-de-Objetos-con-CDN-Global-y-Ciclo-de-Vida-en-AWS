# Estado del proyecto DOMUSNET

## Cómo interpretar este estado

Este documento resume lo que está definido en el repositorio. No equivale a una lectura del estado remoto de Terraform, de la consola AWS/Cloudflare ni de ejecuciones exitosas de GitHub Actions. El despliegue real no se verificó en AWS durante esta revisión.

## Implementado en el código

- Root Terraform con proveedores AWS, Cloudflare y Archive; versión mínima declarada `1.10.5`.
- Módulos de S3, CloudFront, ACM, Route 53, Lambda@Edge, WAF y delegación DNS en Cloudflare.
- Tres buckets cuyo nombre se construye como `domusnet-{assets|uploads|logs}-prod-<account_id>`.
- Backend remoto S3 declarado en `backend.tf`: bucket `domusnet-tfstate-130841270595`, key `domusnet/prod/terraform.tfstate`, región `us-east-1`, cifrado y `use_lockfile`.
- Outputs root declarados: `assets_bucket`, `cloudfront_distribution_id`, `uploads_bucket`, `logs_bucket`, `cloudfront_domain`, `app_url`, `route53_nameservers`, `route53_zone_id`, `acm_validation_records` y `cloudflare_ns_records`.
- Tres workflows en `.github/workflows/`: validación/despliegue Terraform, Checkov/SARIF y publicación estática a S3 + invalidación de CloudFront.
- El workflow de Checkov fija `checkov==3.4.3`.

## Estado desplegado

**No confirmado durante esta revisión.** No se consultó AWS ni Cloudflare y no se ejecutó `terraform apply`/`destroy`. La configuración de Terraform, las variables en `terraform.tfvars` y los outputs esperados no prueban que los recursos existan ni que DNS/certificado/URL estén operativos.

Para confirmar despliegue, el responsable de cuenta debe consultar el backend y los recursos AWS, revisar las últimas ejecuciones CI/CD y verificar DNS, ACM, CloudFront y contenido. Registrar aquí fecha, cuenta/región, commit y evidencia cuando se complete esa verificación.

## Pendientes conocidos

- Confirmar que el bucket de estado existe, está protegido y que OIDC puede acceder al objeto/lockfile.
- Crear/probar las trust policies y políticas de permisos mínimos de ambos roles AWS.
- Configurar secrets requeridos en GitHub y probar los workflows en un entorno controlado.
- Revisar si se requiere aprobación manual antes del `terraform apply` automático en pushes a `main`.
- Confirmar que Checkov debe bloquear el workflow cuando falla; actualmente se permite continuar y se ignoran fallos del comando.
- Verificar en AWS la publicación, DNS, ACM, cabeceras y logs; no reportarlos como completados hasta tener evidencia.
