# 🌐 DOMUSNET — Plataforma de Almacenamiento de Objetos con CDN Global y Ciclo de Vida en AWS

> **Infraestructura para Ti** · Proyecto 04

Plataforma de hosting estático y distribución de activos digitales sobre **AWS**, desplegada 100 % como código con **Terraform**. Combina almacenamiento durable en S3, distribución global con CloudFront, seguridad en el borde (WAF, ACM, Lambda@Edge) y optimización de costos mediante políticas de ciclo de vida.

![AWS](https://img.shields.io/badge/AWS-Cloud-FF9900?logo=amazonaws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.6-7B42BC?logo=terraform&logoColor=white)
![Node.js](https://img.shields.io/badge/Lambda%40Edge-Node.js-339933?logo=nodedotjs&logoColor=white)
![Estado](https://img.shields.io/badge/Estado-En%20desarrollo-yellow)

---

## 📋 Tabla de contenidos

- [Descripción general](#-descripción-general)
- [Objetivos](#-objetivos)
- [Arquitectura](#-arquitectura)
- [Componentes](#-componentes)
- [Flujo de la solicitud](#-flujo-de-la-solicitud)
- [Decisiones de diseño](#-decisiones-de-diseño)
- [Requisitos técnicos](#-requisitos-técnicos)
- [Estructura del repositorio](#-estructura-del-repositorio)
- [Variables de entorno](#-variables-de-entorno)
- [Uso rápido](#-uso-rápido)
- [Riesgos y mitigación](#-riesgos-y-mitigación)
- [Equipo](#-equipo)

---

## 📖 Descripción general

| | |
|---|---|
| **Proyecto** | Plataforma de Almacenamiento de Objetos con CDN Global y Ciclo de Vida en AWS |
| **Plataforma cloud** | Amazon Web Services (AWS) |
| **Dificultad** | Intermedio |
| **Caso de uso** | Distribución de contenido estático y archivos de usuarios, con optimización de costos por ciclo de vida y hardening de seguridad en el borde |
| **Dominio** | `app.domusnet.uk` (delegado desde Cloudflare a Route 53) |

La plataforma separa tres tipos de datos, cada uno en su propio bucket S3:

| Tipo de dato | Bucket | Acceso |
|---|---|---|
| Activos de la aplicación | `domusnet-assets-prod-<account_id>` | Servido públicamente **solo vía CDN** |
| Archivos subidos por usuarios | `domusnet-uploads-prod-<account_id>` | Privado, con ciclo de vida |
| Logs de acceso | `domusnet-logs-prod-<account_id>` | Privado, retención de 90 días |

---

## 🎯 Objetivos

### General
Diseñar, construir y automatizar mediante Infraestructura como Código una plataforma de almacenamiento de objetos con distribución global de contenido en AWS, aplicando buenas prácticas de seguridad, optimización de costos y despliegue continuo.

### Específicos
- [x] Configurar buckets S3 con mínimo privilegio, cifrado en reposo y versionado.
- [x] Configurar CloudFront con **Origin Access Control (OAC)** para eliminar el acceso público directo al origen.
- [x] Solicitar, validar y asociar certificados TLS con **ACM** para un dominio personalizado bajo HTTPS.
- [x] Implementar ciclo de vida en S3: `Standard → Standard-IA → Glacier → eliminación`.
- [x] Desarrollar y desplegar una función **Lambda@Edge** que inyecte cabeceras HTTP de seguridad.
- [ ] Construir un pipeline CI/CD que publique contenido e invalide la caché del CDN. *(pendiente de automatización)*
- [ ] Documentar arquitectura, costos y métricas de desempeño.

---

## 🏗️ Arquitectura

> 📌 El diagrama editable (`DOMUSNET_Arquitectura.drawio`) es compatible con [diagrams.net](https://app.diagrams.net) y usa la librería oficial de íconos de AWS.

El flujo de DNS resuelve así:

```
Cloudflare (solo registros NS de delegación para "app")
      ↓
Route 53 (zona app.domusnet.uk, alias A/AAAA → CloudFront)
      ↓
WAF (Web ACL scope CLOUDFRONT)
      ↓
CloudFront (distribución global, origen S3 vía OAC)
      ↓
Lambda@Edge (viewer-response: cabeceras de seguridad)
      ↓
S3 assets (origen privado, sin acceso público directo)
```

---

## 🧩 Componentes

| Componente | Función | Configuración clave |
|---|---|---|
| **Cloudflare** | Gestión del dominio raíz `domusnet.uk` y registros NS de delegación | 4 registros `NS` para `app.domusnet.uk` apuntando a Route 53 |
| **Route 53** | Zona alojada autoritativa para `app.domusnet.uk` | Registros `A` y `AAAA` alias hacia CloudFront |
| **AWS WAF** | Filtrado de tráfico malicioso en el borde | Web ACL scope `CLOUDFRONT`, reglas OWASP Common RuleSet + rate limit 2000 req/IP |
| **CloudFront** | CDN global | Origen S3 vía OAC, TTL 86400 s para assets, sin caché para `index.html`, certificado ACM, logging a S3 |
| **ACM** | Certificado TLS | Región `us-east-1`, validación por DNS |
| **Lambda@Edge** | Hardening de cabeceras HTTP | Node.js 20.x, trigger `viewer-response`, inyecta HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy, Content-Security-Policy |
| **S3 — assets** | Origen del hosting estático | OAC, cifrado SSE-S3, versionado, Block Public Access, política de bucket restringida a CloudFront |
| **S3 — uploads** | Archivos de usuario | Privado, CORS, lifecycle: Standard → IA (30 d) → Glacier (90 d) → eliminación (365 d) |
| **S3 — logs** | Logs de CloudFront | Retención 90 días, sin acceso público, `log-delivery-write` ACL |
| **Terraform** | Aprovisionamiento declarativo | Módulos por servicio, backend S3 con `use_lockfile`, región `us-east-1` |

---

## 🔄 Flujo de la solicitud

1. El usuario resuelve `app.domusnet.uk`.
2. Cloudflare responde con los registros `NS` de Route 53 (delegación del subdominio).
3. Route 53 devuelve un registro alias `A`/`AAAA` hacia la distribución de CloudFront.
4. La solicitud pasa por **AWS WAF** (reglas OWASP Top 10 + limitación de tasa).
5. **CloudFront** responde desde el edge más cercano; si no hay caché, obtiene el objeto del origen vía **OAC** sin exponer el bucket S3 públicamente.
6. **Lambda@Edge** (`viewer-response`) inyecta las cabeceras de seguridad:
   - `Strict-Transport-Security`
   - `X-Content-Type-Options`
   - `X-Frame-Options`
   - `Referrer-Policy`
   - `Content-Security-Policy`
7. El certificado de **ACM** (`us-east-1`) garantiza que todo el tráfico viaje por HTTPS.
8. Los archivos de usuarios se guardan en `s3-uploads-prod` y transicionan automáticamente a clases más económicas.
9. Los logs de CloudFront llegan a `s3-logs` y alimentan métricas en **CloudWatch**.

---

## 🧠 Decisiones de diseño

- **Buckets separados por tipo de dato:** evita que una política de acceso o de ciclo de vida afecte a otro caso de uso y facilita auditar permisos.
- **OAC en lugar de acceso público:** todo el tráfico pasa por CloudFront, centralizando caché, TLS y seguridad de borde.
- **Lambda@Edge en `viewer-response`:** garantiza que las cabeceras se apliquen tanto a respuestas cacheadas como a las del origen.
- **Ciclo de vida en 3 fases:** IA a los 30 días y Glacier a los 90 balancea costo con acceso ocasional.
- **Todo vía Terraform:** infraestructura versionada, revisable en pull requests y reproducible en otra cuenta o entorno.
- **Delegación de subdominio vía Cloudflare:** como el dominio raíz (`domusnet.uk`) está registrado en Cloudflare Registrar (que bloquea cambios de NS del apex), se delega solo `app.domusnet.uk` a Route 53 mediante registros `NS` creados automáticamente por Terraform con el provider de Cloudflare.

---

## 🛠️ Requisitos técnicos

| Requisito | Detalle |
|---|---|
| **Cuenta AWS** | Permisos administrativos para IAM, S3, CloudFront, Lambda, ACM, Route 53 y WAF |
| **Dominio** | `domusnet.uk` en Cloudflare Registrar; subdominio `app` delegado a Route 53 |
| **Terraform** | CLI `>= 1.6`; backend remoto S3 con `use_lockfile` |
| **Cloudflare** | API Token con permiso `DNS:Edit` sobre la zona `domusnet.uk` |
| **Node.js** | Desarrollo de la función Lambda@Edge |
| **Pruebas** | [securityheaders.com](https://securityheaders.com) para validar cabeceras |

---

## 📁 Estructura del repositorio

```
.
├── .env.example                  # Template de variables de entorno (no subirse)
├── .gitignore                    # Ignora .env, .terraform, *.tfstate, etc.
├── backend.tf                    # Backend remoto S3 (bucket domusnet-tfstate-130841270595)
├── main.tf                       # Orquestador de módulos
├── outputs.tf                    # Salidas de Terraform
├── providers.tf                  # Proveedores AWS y Cloudflare
├── terraform.tfvars              # Valores de variables (incluye Cloudflare zone_id)
├── variables.tf                  # Definición de variables de entrada
├── versions.tf                   # Versiones de proveedores (AWS, archive, cloudflare)
├── app/
│   ├── index.html                # Sitio estático de prueba
│   └── error.html                # Página de error personalizada
├── lambda/
│   └── edge-headers/
│       └── index.js              # Lambda@Edge: inyección de cabeceras de seguridad
├── envs/
│   └── prod.tfvars               # Archivo de entorno (actualmente sin variables, todo en terraform.tfvars)
├── modules/
│   ├── acm/                      # Certificado TLS (us-east-1, validación DNS)
│   ├── cloudflare-delegation/    # Registros NS en Cloudflare (delegación de app.domusnet.uk)
│   ├── cloudfront/               # Distribución CDN, OAC, políticas de caché, logging
│   ├── lambda-edge/              # Función Lambda@Edge (Node.js 20.x, viewer-response)
│   ├── route53/                  # Zonas alojadas (app.domusnet.uk + apex documental)
│   ├── s3/                       # 3 buckets (assets, uploads, logs) con lifecycle, CORS, SSE, versionado
│   └── waf/                      # Web ACL scope CLOUDFRONT (OWASP + rate limit)
```

---

## 🔐 Variables de entorno

El token de API de Cloudflare **no debe subirse al repositorio**. Se provee a través de variable de entorno:

```powershell
$env:TF_VAR_cloudflare_api_token = "TU_TOKEN_DE_CLOUDFLARE"
```

O usando el archivo de plantilla:

```powershell
# Copiar .env.example a .env y completar:
cp .env.example .env
# Luego cargar las variables antes de ejecutar Terraform
```

El archivo `.env` está ignorado por `.gitignore` y nunca debe comprometerse.

---

## 🚀 Uso rápido

```powershell
# 1. Clonar el repositorio
git clone https://github.com/ISCOUTB/Plataforma-de-Almacenamiento-de-Objetos-con-CDN-Global-y-Ciclo-de-Vida-en-AWS.git
cd Plataforma-de-Almacenamiento-de-Objetos-con-CDN-Global-y-Ciclo-de-Vida-en-AWS

# 2. Configurar variable de entorno de Cloudflare (obligatorio)
$env:TF_VAR_cloudflare_api_token = "TU_TOKEN_DE_CLOUDFLARE"

# 3. Inicializar Terraform
terraform init

# 4. Revisar los cambios
terraform plan

# 5. Aplicar la infraestructura
terraform apply
```

> **Nota sobre DNS:** Tras el `apply`, Terraform crea los registros `NS` en Cloudflare para `app.domusnet.uk`. Debes verificar que la delegación esté activa antes de que ACM pueda validar el certificado por DNS. El `apply` completo incluye la creación del certificado, CloudFront, WAF, Lambda@Edge y los registros alias de Route 53.

### Publicar contenido estático (despliegue manual del sitio)

Una vez la infraestructura está creada:

```powershell
# Subir archivos al bucket de assets (privado, solo accesible vía CloudFront)
aws s3 sync app/ s3://domusnet-assets-prod-<account_id> --delete --profile DomusnetCol

# Invalidar caché de CloudFront
aws cloudfront create-invalidation --distribution-id <ID_DISTRIBUCION> --paths "/*" --profile DomusnetCol
```

---

## ⚠️ Riesgos y mitigación

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Costos inesperados en AWS | Medio | AWS Budgets y alarmas; revisión semanal; capa gratuita |
| Certificado ACM fuera de `us-east-1` | Alto | Región fija `us-east-1` en todos los recursos (CloudFront, WAF, Lambda@Edge requieren us-east-1) |
| Pérdida de datos por errores de lifecycle | Alto | Versiónado activo en buckets; pruebas en staging |
| Lambda@Edge no se destruye | Medio | Las réplicas en edge locations impiden borrar la función inmediatamente; esperar a que CloudFront las limpie |
| Retrasos en validación de dominio/DNS | Medio | Delegar `app.domusnet.uk` desde Cloudflare desde la semana 1 |

---

## 👥 Equipo

**DOMUSNET** — 4 integrantes. Las decisiones de diseño se validan en revisiones semanales y todo el código se integra mediante pull requests revisados por al menos un compañero distinto al autor.

| Integrante | Rol | Componentes a cargo |
|---|---|---|
| **Diego Rosales** | Cloud & IaC | S3 (buckets, políticas, lifecycle), estructura del repositorio Terraform |
| **Sebastian Torres** | DevOps / CI-CD | Pipeline GitHub Actions, sincronización S3, invalidación de caché *(pendiente)* |
| **Jose Chima** | Seguridad Cloud | CloudFront, ACM, WAF, Lambda@Edge, cabeceras HTTP |
| **Ellen Ordoñez** | QA, Costos y Documentación | CloudWatch, securityheaders.com, informes y documentación |

---

## 🗂️ Estado de entregas

| Entrega | Contenido | Estado |
|---|---|---|
| **Entrega 1** | Propuesta de proyecto, diagrama de arquitectura, roles y plan semanal | ✅ Completado |
| **Entrega 2** | Código Terraform de S3 (buckets, políticas, cifrado, versionado, lifecycle) | ✅ Implementado |
| **Entrega 3** | Terraform de CloudFront, ACM, Route 53, WAF, delegación Cloudflare, Lambda@Edge | ✅ Implementado |
| **Entrega final** | Pipeline CI/CD completo, análisis de costos, reporte de cabeceras, métricas y presentación | 🔲 Pendiente |

---

## 🔧 Notas sobre el destroy

Al destruir la infraestructura con `terraform destroy`, la función Lambda@Edge puede tardar varios minutos en eliminarse porque AWS mantiene réplicas en los edge locations de CloudFront mientras exista la distribución asociada. Se recomienda destruir primero el módulo `cloudfront` si el destroy completo se atora:

```powershell
terraform destroy -var-file="terraform.tfvars" -target=module.cloudfront
terraform destroy -var-file="terraform.tfvars"
```

---

<p align="center"><b>DOMUSNET</b> · Infraestructura para Ti</p>
