# Despliegue paso a paso — Chatbot de Apoyo Académico UNAB

Guía completa para llevar el proyecto desde cero hasta una demo funcional:
Supabase → Gemini → pipeline RAG → servidor MCP en AWS EC2 → workflows en
n8n Cloud → app Flutter.

> Tiempo estimado: **2 a 3 horas** la primera vez.
> Costo estimado de la demo: **USD 0–5** (EC2 free tier + tokens de Gemini).

---

## 1. Prerrequisitos

### 1.1 Cuentas y servicios

| Servicio | Plan mínimo | Para qué |
|----------|-------------|----------|
| [Supabase](https://supabase.com) | Free | PostgreSQL 17 + `pgvector` |
| [n8n Cloud](https://n8n.io) | Trial / Starter | Orquestación, webhooks y credencial Gemini para el LLM |
| Embeddings: [Gemini](https://aistudio.google.com/apikey) o [Cohere](https://dashboard.cohere.com/api-keys) | Gratis | Búsqueda vectorial del RAG (1536d) |
| [AWS](https://aws.amazon.com) | Free tier / `t3.micro` | EC2 Ubuntu para el MCP |
| [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) | Gratis | HTTPS para el MCP sin abrir puertos |

### 1.2 Software local

| Herramienta | Versión | Verificar con |
|-------------|---------|---------------|
| Git | cualquiera | `git --version` |
| Python | 3.10+ | `python --version` |
| Docker Desktop | reciente (opcional, para probar el MCP en local) | `docker --version` |
| Flutter | **3.35+** (Dart 3.9) | `flutter --version` |
| Android Studio / SDK | API 24+ | `flutter doctor -v` |
| JDK | 17 | `java -version` |

### 1.3 Orden recomendado

```
1. Supabase   → crear proyecto y ejecutar SQL
2. Gemini     → crear API key en AI Studio
3. RAG        → generar embeddings (rag/ingest.py)
4. MCP        → desplegar en EC2 + HTTPS
5. n8n        → importar workflows, credenciales y activar
6. App        → compilar APK apuntando a n8n
7. Verificación de punta a punta
```

Cada paso se puede probar de forma aislada antes de continuar. **No avances al
siguiente si el anterior no responde.**

---

## 2. Supabase (base de datos)

### 2.1 Crear el proyecto

1. Entra a <https://supabase.com/dashboard> → **New project**.
2. Nombre: `unab-chatbot`.
3. Región: la más cercana (ej. `us-east-1`).
4. Guarda la **contraseña de la base de datos** en un gestor de secretos.
5. Espera a que el proyecto termine de aprovisionarse (2–3 min).

### 2.2 Ejecutar los scripts SQL

Abre **SQL Editor** y ejecuta **en este orden**, uno por uno. Cada script debe
terminar sin errores antes de pasar al siguiente:

| # | Archivo | Qué crea | Verificación |
|---|---------|----------|--------------|
| 1 | `database/01_schema.sql` | Esquema `unab`, tablas, índices, triggers | Sin errores |
| 2 | `database/02_seed.sql` | 12 programas, 51 cursos, 30 estudiantes, 908 filas de historial | Mensaje de conteo al final |
| 3 | `database/03_rag_pgvector.sql` | Extensión `vector`, tabla de chunks, HNSW, `buscar_conocimiento` | `Database → Extensions → vector` activo |
| 4 | `database/04_vistas.sql` | 11 vistas analíticas | Sin errores |
| 5 | `database/05_rls_policies.sql` | RLS y políticas para Supabase Auth | **Solo en Supabase** (usa `auth.uid()`) |
| 6 | `database/06_consultas_demo.sql` | Consultas de verificación (opcional) | Resultados coherentes |
| 7 | `database/07_conocimiento_rag.sql` | 6 documentos y 23 chunks iniciales (sin embedding); luego `ingest.py` genera 27 con overlap | `documentos_vectoriales = 23` tras el SQL |
| 8 | `database/08_actualizar_demo.sql` | Periodo, calendario y noticias relativos a hoy | Fechas futuras |

> Si ejecutas en PostgreSQL local, **omite** `05_rls_policies.sql`.

Verificación rápida en el SQL Editor:

```sql
SELECT 'programas' AS tabla, COUNT(*) FROM unab.programas
UNION ALL SELECT 'cursos', COUNT(*) FROM unab.cursos
UNION ALL SELECT 'prerrequisitos', COUNT(*) FROM unab.prerrequisitos
UNION ALL SELECT 'estudiantes', COUNT(*) FROM unab.estudiantes
UNION ALL SELECT 'historial', COUNT(*) FROM unab.historial_academico
UNION ALL SELECT 'documentos', COUNT(*) FROM unab.documentos
UNION ALL SELECT 'chunks', COUNT(*) FROM unab.documentos_vectoriales;

-- Caso estrella de la demo
SELECT nombre_completo, semestre_actual, promedio_acumulado,
       creditos_aprobados, cursos_reprobados
FROM unab.v_estado_estudiante
WHERE id_estudiante = '10045234';
```

Salida esperada: `51` cursos, `30` estudiantes, `908` filas de historial,
`6` documentos, `23` chunks. Jhon García: semestre 3, promedio 3.69,
30 créditos aprobados, 1 curso reprobado.

### 2.3 Obtener la cadena de conexión

**Project Settings → Database → Connection string**:

| Uso | Tipo | Puerto | Nota |
|-----|------|--------|------|
| Servidor MCP (psycopg2) | **Session pooler** | `5432` | Recomendado; soporta pool propio |
| n8n (nodos Postgres + memoria) | **Session pooler** | `5432` | Evita el transaction pooler |
| `rag/ingest.py` | Session pooler o directa | `5432` | `sslmode=require` |

> **No uses el transaction pooler (`6543`)** con el nodo de memoria de n8n ni
> con el pool persistente del MCP: las conexiones se reutilizan y el pooler
> transaccional puede cerrarlas entre operaciones.

Formato de la cadena:

```
postgresql://postgres.<project-ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:5432/postgres?sslmode=require
```

### 2.4 Notas de seguridad

- El backend (MCP y n8n) se conecta con el usuario `postgres`, que **omite RLS**.
  Es intencional: es un backend de confianza. No expongas esa contraseña en la app.
- Las políticas RLS protegen el acceso con **Supabase Auth** (clientes públicos).
- No habilites `pg_graphql` ni endpoints públicos que no uses.

---

## 3. LLM y embeddings

### 3.1 LLM de los agentes (n8n Cloud)

Los tres workflows con agente usan el nodo **Gemini Chat Model**
(`models/gemini-3.5-flash-lite`, temperatura 0.2) con una credencial
**Google Gemini(PaLM) API** y la clave personal de Google AI Studio.
No se usa OpenAI: la clave es gratuita e independiente del correo institucional.

### 3.2 Embeddings del RAG (tres opciones, todas 1536d)

| Proveedor | Clave | Costo | Notas |
|-----------|-------|-------|-------|
| Google Gemini | `GEMINI_API_KEY` | Gratis (cuota AI Studio) | Requiere un proyecto de Google Cloud activo |
| Cohere | `COHERE_API_KEY` | Trial gratis: 1.000 llamadas/mes | No depende de Google; 96 textos por petición |
| OpenAI | `OPENAI_API_KEY` | USD 0.02 / 1M tokens | De pago |

> Los tres devuelven **1536 dimensiones**, así que la columna `vector(1536)` y el
> índice HNSW sirven sin cambios al cambiar de proveedor.

---

## 4. Pipeline RAG (embeddings)

Los 23 chunks iniciales se cargaron **sin embedding** en el paso 2.2 para que la
búsqueda textual funcione desde el primer momento. Este paso activa la búsqueda
vectorial y, con `--reindex`, deja 27 chunks (7 documentos, overlap de 160).

### 4.1 Preparar el entorno

```powershell
cd rag
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

Copy-Item .env.example .env
notepad .env
```

En Linux/macOS:

```bash
cd rag
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
nano .env
```

Completa `.env`:

```env
# Embeddings: elige UNA opción
EMBEDDING_PROVIDER=gemini
GEMINI_API_KEY=AIza...
GEMINI_EMBEDDING_MODEL=gemini-embedding-001

# Alternativa sin Google (trial gratis)
# EMBEDDING_PROVIDER=cohere
# COHERE_API_KEY=...
# COHERE_EMBEDDING_MODEL=embed-v4.0

# Alternativa de pago
# EMBEDDING_PROVIDER=openai
# OPENAI_API_KEY=sk-...

EMBEDDING_DIMENSIONS=1536

DATABASE_URL=postgresql://postgres.<ref>:<PASSWORD>@aws-0-<region>.pooler.supabase.com:5432/postgres?sslmode=require
```

### 4.2 Generar los embeddings

```bash
# Solo los chunks que tienen embedding NULL (modo por defecto)
python ingest.py --reembed

# Estado del catálogo
python ingest.py --stats
```

Salida esperada:

```
Documentos: 6 | Chunks: 23 | Con embedding: 23
```

### 4.3 Verificar la búsqueda semántica

En el SQL Editor de Supabase:

```sql
SELECT contenido, metadata->>'fuente' AS fuente, similitud
FROM unab.buscar_conocimiento(
    (SELECT embedding FROM unab.documentos_vectoriales
     WHERE embedding IS NOT NULL LIMIT 1),
    5,
    '{}'::jsonb
);
```

Debe devolver 5 chunks ordenados por similitud.

### 4.4 Cuándo repetir este paso

| Situación | Comando |
|-----------|---------|
| Editaste un documento | `python ingest.py --reindex` |
| Agregaste un `.md` nuevo | `python ingest.py --file documentos/nuevo.md` |
| Faltan embeddings | `python ingest.py --reembed` |
| Quieres revisar el chunking sin costos | `python ingest.py --reindex --dry-run` |

> El pipeline es idempotente por fuente: borra y recarga los chunks del archivo
> sin duplicar. Ver [`../rag/README.md`](../rag/README.md).

---

## 5. Servidor MCP en AWS EC2

### 5.1 Crear la instancia

1. **EC2 → Launch instance**.
2. Nombre: `unab-mcp`.
3. AMI: **Ubuntu Server 26.04 LTS** (la instancia desplegada reporta
   `Ubuntu 26.04 LTS`; también funciona en 24.04 LTS).
4. Tipo: `t3.micro` (demo) o `t3.small` (más holgado).
5. Key pair: crea uno y guarda el `.pem`.
6. Security Group (inbound):

| Puerto | Origen | Para qué |
|--------|--------|----------|
| 22 | **Tu IP** | SSH |
| 80 | `0.0.0.0/0` | Validación de Caddy / redirección a HTTPS |
| 443 | `0.0.0.0/0` | MCP por HTTPS |
| 9000 | — | **Cerrado** si usas Caddy |

7. Storage: 10–20 GB gp3.
8. Launch y asocia una **IP elástica** (para que la IP pública no cambie).

> Si vas a probar sin dominio, abre `9000` temporalmente y usa
> `http://IP:9000/mcp`. El token viajará sin cifrar: solo para pruebas.

### 5.2 Instalar Docker

```bash
ssh -i unab-mcp.pem ubuntu@TU_IP_PUBLICA

sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

### 5.3 Subir el proyecto

**Opción git:**

```bash
git clone https://github.com/TU_USUARIO/unab-chatbot.git
cd unab-chatbot/mcp-server
```

**Opción scp** (desde tu equipo):

```powershell
scp -i unab-mcp.pem -r mcp-server ubuntu@TU_IP_PUBLICA:~/
```

### 5.4 Configurar `.env`

```bash
cd ~/mcp-server        # o ~/unab-chatbot/mcp-server
cp .env.example .env
nano .env
```

Valores mínimos de producción:

```env
APP_NAME=UNAB Academic MCP
APP_ENV=production
LOG_LEVEL=INFO

DB_HOST=aws-0-<region>.pooler.supabase.com
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres.<project-ref>
DB_PASSWORD=<PASSWORD>
DB_SSLMODE=require
DB_POOL_MIN=1
DB_POOL_MAX=10

MCP_HOST=0.0.0.0
MCP_PORT=9000
MCP_PATH=/mcp

# Genera el token con: openssl rand -hex 32
MCP_API_TOKEN=<TOKEN_LARGO>

MCP_DNS_PROTECTION=true
MCP_ALLOWED_HOSTS=localhost:*,127.0.0.1:*,<IP_PUBLICA>:9000

GEMINI_API_KEY=AIza...
GEMINI_EMBEDDING_MODEL=gemini-embedding-001
# Alternativas: COHERE_API_KEY=... | OPENAI_API_KEY=sk-...
EMBEDDING_DIM=1536
```

> `MCP_ALLOWED_HOSTS` no acepta un `*` suelto. Usa `host:*` o el host exacto.
> Si usas el túnel de Cloudflare, agrega el hostname `*.trycloudflare.com` que te asigne.

### 5.5 Arrancar el contenedor

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f --tail 50
```

Prueba local en la EC2:

```bash
curl http://127.0.0.1:9000/health
```

Respuesta esperada:

```json
{ "status": "ok", "app": "UNAB Academic MCP", "database": "ok" }
```

### 5.6 Exponer el MCP por HTTPS

**Opción A — Túnel de Cloudflare (no requiere abrir puertos):**

```bash
curl -fsSL -o /tmp/cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i /tmp/cloudflared.deb

cd ~/unab-chatbot/mcp-server
sudo cp deploy/cloudflared-unab.service /etc/systemd/system/
sudo cp deploy/unab-tunel-sync.service deploy/unab-tunel-sync.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared-unab.service unab-tunel-sync.timer

grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /home/ubuntu/cloudflared-unab.log | tail -1
```

La URL queda como `https://<algo>.trycloudflare.com/mcp`. Cambia si cloudflared
se reinicia; `unab-tunel-sync.timer` resincroniza `MCP_ALLOWED_HOSTS` cada 5
minutos y `n8n/actualizar_mcp.py` reescribe la URL en los workflows.

**Opción B — Caddy + sslip.io (URL fija, requiere puertos 80/443):**

1. Abre `80` y `443` en el Security Group y cierra `9000`.
2. Ejecuta el instalador incluido:

```bash
cd ~/unab-chatbot/mcp-server
./deploy/instalar.sh
```

3. Edita `/etc/caddy/Caddyfile` (o usa `DOMINIO=... ./deploy/instalar.sh`):

```caddyfile
54-211-28-77.sslip.io {
    reverse_proxy 127.0.0.1:9000
}
```

4. Ajusta el `.env` y reinicia:

```env
MCP_ALLOWED_HOSTS=localhost:*,127.0.0.1:*,54-211-28-77.sslip.io,54-211-28-77.sslip.io:*
```

```bash
sudo systemctl reload caddy
docker compose up -d
curl https://54-211-28-77.sslip.io/health
```

### 5.7 Probar las 18 herramientas

Desde tu equipo:

```powershell
cd mcp-server
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

python test_client.py --url https://TU_ENDPOINT/mcp --token <TOKEN>
```

Debe listar las 18 herramientas y ejecutarlas contra Supabase. Todas deben
responder con `status: ok`.

> Si ves `421 Invalid Host header`, el dominio o la IP no están en
> `MCP_ALLOWED_HOSTS`. Si ves `401`, el token no coincide.

### 5.8 Actualizar el servidor

```bash
cd ~/unab-chatbot/mcp-server
git pull
docker compose up -d --build
docker image prune -f
```

---

## 6. n8n Cloud (workflows)

### 6.1 Importar

1. **Workflows → Create Workflow → ⋯ → Import from File**.
2. Importa los cuatro archivos de `n8n/`:
   - `wf01_rag_institucional.json`
   - `wf02_calendario.json`
   - `wf03_historial_mcp.json`
   - `wf04_noticias.json`
3. Guarda cada uno con `Ctrl/Cmd + S`.

Al importar aparecerán credenciales marcadas como *Credential not found*. Es
normal: los JSON traen referencias de ejemplo.

### 6.2 Crear credenciales

| Credencial | Tipo | Dónde se asigna |
|------------|------|-----------------|
| `UNAB Gemini` | Google Gemini(PaLM) (`googlePalmApi`) | Nodos `Gemini Chat Model` de WF01–WF03 |
| `UNAB Supabase Postgres` | Postgres (`postgres`) | Registro de conversaciones, memoria, noticias |
| `UNAB MCP Bearer` | Bearer Auth (`httpBearerAuth`) | Nodos `MCP Client *` |

**Postgres** (usa Session pooler):

| Campo | Valor |
|-------|-------|
| Host | `aws-0-<region>.pooler.supabase.com` |
| Database | `postgres` |
| User | `postgres.<project-ref>` |
| Password | la de Supabase |
| Port | `5432` |
| SSL | `require` |

**MCP Client Tool** (en cada nodo `MCP Client *`):

| Campo | Valor |
|-------|-------|
| Endpoint | `https://TU_ENDPOINT/mcp` |
| Server Transport | **HTTP Streamable** |
| Authentication | **Bearer Auth** |
| Credential | `UNAB MCP Bearer` |
| Tools to include | *Selected* (según el workflow) |
| Timeout | `60000` ms |

> Detalle por workflow en [`../n8n/README.md`](../n8n/README.md), sección 7.

### 6.3 Probar antes de activar

Para cada workflow:

1. Abre el workflow → **Test workflow**.
2. Usa la **Test URL** del nodo Webhook.
3. Envía el JSON de ejemplo (ver `n8n/README.md`, sección 4).

Prueba mínima desde PowerShell:

```powershell
Invoke-RestMethod -Method Post `
  -Uri "https://TU-INSTANCIA.app.n8n.cloud/webhook-test/unab/rag" `
  -ContentType "application/json" `
  -Body (@{ session_id = "ses-test"; pregunta = "¿Cuáles son los requisitos de grado?" } | ConvertTo-Json)
```

### 6.4 Activar

1. Asigna credenciales en **todos** los nodos.
2. Activa cada workflow con el interruptor **Active**.
3. Copia la **Production URL** de cada webhook.
4. Para WF04, ejecuta **Execute workflow** una vez para poblar `unab.noticias`
   (el cron corre cada 6 h).

### 6.5 Verificar los endpoints estructurados

```powershell
# Calendario
Invoke-RestMethod -Method Post `
  -Uri "https://TU-INSTANCIA.app.n8n.cloud/webhook/unab/calendario/lista" `
  -ContentType "application/json" `
  -Body (@{ texto = "examen"; categoria = "examenes" } | ConvertTo-Json)

# Resumen académico
Invoke-RestMethod -Method Post `
  -Uri "https://TU-INSTANCIA.app.n8n.cloud/webhook/unab/academico/resumen" `
  -ContentType "application/json" `
  -Body (@{ id_estudiante = "10045234" } | ConvertTo-Json)

# Noticias
Invoke-RestMethod -Method Post `
  -Uri "https://TU-INSTANCIA.app.n8n.cloud/webhook/unab/noticias" `
  -ContentType "application/json" `
  -Body (@{ texto = "beca"; categoria = "beca" } | ConvertTo-Json)
```

Estos tres **no usan LLM**. Si fallan, revisa la credencial Postgres y las
vistas, no en el LLM.

### 6.6 Seguridad de los webhooks (producción)

La demo deja los webhooks públicos. Antes de un entorno real:

1. En cada nodo Webhook → **Authentication → Header Auth**.
2. Crea una credencial Header Auth (ej. `X-UNAB-Key`).
3. Envía el header desde la app (requiere un cambio pequeño en
   `app/lib/services/n8n_service.dart`).
4. Restringe CORS a los orígenes reales.

---

## 7. App Flutter (Android)

### 7.1 Proyecto Android

El repositorio ya incluye `app/android/` generado con Flutter (`applicationId`
`co.edu.unab.unab_chatbot`). Si necesitas regenerarlo:

```powershell
cd app
flutter create --platforms=android --org co.edu.unab --project-name unab_chatbot .
flutter pub get
```

> `flutter create` no sobrescribe `lib/`, `pubspec.yaml` ni el
> `AndroidManifest.xml` ya editado.

### 7.2 Permiso de Internet

En `app/android/app/src/main/AndroidManifest.xml`, antes de `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Sin esto, el APK **release** falla con `SocketException`. En este repositorio
el permiso ya está agregado.

### 7.3 Compilar apuntando a n8n

```powershell
flutter run --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
```

Para el APK:

```powershell
flutter build apk --release `
  --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
```

Salida: `app/build/app/outputs/flutter-apk/app-release.apk`.

> `--dart-define` queda grabado en el binario. Si cambia la URL de n8n hay que
> recompilar.

### 7.4 Flujo de demo

1. **Login** → *Probar con el estudiante demo* (`10045234`).
2. **Chat** → `¿Cuáles son los requisitos de grado?`
3. **Calendario** → filtrar *Exámenes*.
4. **Académico** → avance, alertas y `IS301` bloqueado por `IS201`.
5. **Noticias** → filtrar *Becas* y abrir una convocatoria.

Detalle en [`../app/README.md`](../app/README.md).

---

## 8. Verificación de punta a punta

Ejecuta esta lista en orden. Si algo falla, corrige antes de seguir.

### 8.1 Infraestructura

- [ ] `GET https://TU_ENDPOINT/health` → `{"status":"ok","database":"ok"}`
- [ ] `python test_client.py --url https://TU_ENDPOINT/mcp --token <TOKEN>` → 18 herramientas OK
- [ ] En Supabase: `SELECT COUNT(*) FROM unab.documentos_vectoriales WHERE embedding IS NOT NULL;` → `23`
- [ ] En Supabase: `SELECT COUNT(*) FROM unab.calendario_academico WHERE fecha_inicio >= CURRENT_DATE;` → `> 0`

### 8.2 n8n

- [ ] Los 4 workflows están **Active**.
- [ ] `POST /webhook/unab/rag` responde `ok: true` con texto.
- [ ] `POST /webhook/unab/calendario/lista` responde `eventos` con fechas futuras.
- [ ] `POST /webhook/unab/academico/resumen` responde `avance.porcentaje_avance = 18.8`.
- [ ] `POST /webhook/unab/noticias` responde `total > 0`.
- [ ] `SELECT COUNT(*) FROM unab.conversaciones;` aumentó tras las pruebas.

### 8.3 App

- [ ] `flutter analyze` sin errores.
- [ ] Login con `10045234` funciona.
- [ ] Las cuatro pestañas cargan datos.
- [ ] El chat renderiza Markdown y abre enlaces.
- [ ] El APK release se instala y conecta (no solo en debug).

### 8.4 Caso estrella

Pregunta en el chat académico:

> «¿Qué puedo matricular el próximo semestre?»

El agente debe mencionar que **Cálculo Multivariado (IS301)** está bloqueado
porque **Cálculo Integral (IS201)** está reprobado (nota 2.4), y proponer
alternativas que respeten prerrequisitos y créditos.

---

## 9. Mantenimiento y operación

### 9.1 Antes de cada demo

1. Abre `database/08_actualizar_demo.sql` y copia todo su contenido.
2. Pégalo en el **SQL Editor** de Supabase y ejecútalo.

No toca el pensum ni el historial: solo recalcula el periodo activo, el
calendario y las noticias con fechas relativas a `CURRENT_DATE`.

Si trabajas con `psql` en local también puedes usar `\i database/08_actualizar_demo.sql`.

### 9.2 Actualizaciones

| Componente | Procedimiento |
|------------|---------------|
| MCP | `git pull && docker compose up -d --build` en la EC2 |
| n8n | Reimportar el JSON actualizado o editar los nodos |
| RAG | `python ingest.py --reindex` tras editar documentos |
| App | Recompilar el APK con la nueva `--dart-define` |

### 9.3 Monitoreo

```bash
# MCP
docker compose logs -f --tail 100
docker inspect --format '{{json .State.Health}}' unab-mcp

# n8n
# Workflows → Executions → filtrar por error
```

En Supabase:

```sql
SELECT tipo, COUNT(*) AS consultas, ROUND(AVG(latencia_ms)) AS latencia_prom
FROM unab.conversaciones
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY tipo;

SELECT * FROM unab.v_kpis_chatbot;
```

### 9.4 Rotación de secretos

| Secreto | Cómo rotarlo |
|---------|--------------|
| `MCP_API_TOKEN` | `openssl rand -hex 32` → actualizar `.env`, reiniciar MCP y credencial de n8n |
| Gemini API key | Crear nueva en AI Studio → actualizar n8n y `rag/.env` |
| Password de Supabase | **Project Settings → Database → Reset password** → actualizar MCP, n8n y RAG |

### 9.5 Respaldos

- Supabase Free incluye backups diarios limitados. Para producción, habilita
  PITR o exporta con `pg_dump`.
- Guarda una copia de los JSON de n8n y del `.env` (fuera del repositorio).

---

## 10. Costos estimados (demo)

| Servicio | Consumo | Costo |
|----------|---------|-------|
| Supabase | Free tier | USD 0 |
| EC2 `t3.micro` | 730 h (free tier 12 meses) | USD 0 |
| IP elástica | Asociada a instancia | USD 0 |
| Embeddings | 27 chunks | USD 0 (Gemini o Cohere trial) |
| Gemini chat | ~100 consultas de demo | USD 0 (cuota gratuita) |
| n8n Cloud | Trial | USD 0 |
| Cloudflare Tunnel | HTTPS sin abrir puertos | USD 0 |

> Si la EC2 sale del free tier: ~USD 8–10/mes por `t3.micro`.

---

## 11. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `relation "unab.cursos" does not exist` | Faltan scripts SQL | Ejecuta `01_schema.sql` y `02_seed.sql` |
| `extension "vector" is not available` | pgvector no habilitado | Ejecuta `03_rag_pgvector.sql` o actívalo en *Extensions* |
| `401 unauthorized` en el MCP | Token ausente o distinto | Revisa `MCP_API_TOKEN` y la credencial Bearer de n8n |
| `421 Invalid Host header` | Host no permitido | Agrega IP/dominio exacto a `MCP_ALLOWED_HOSTS` |
| `/health` responde 503 | Sin conexión a Supabase | Revisa credenciales, `DB_SSLMODE=require` y el pooler |
| `password authentication failed` | Usuario mal formado | Usa `postgres.<project-ref>` |
| n8n: `Credential not found` | Referencias de ejemplo | Crea y asigna las 3 credenciales |
| `404` desde la app | Workflow inactivo o URL de test | Activa el workflow y usa la Production URL |
| Calendario vacío | Fechas vencidas | Ejecuta `08_actualizar_demo.sql` |
| Noticias vacías | WF04 nunca corrió | **Execute workflow** en WF04 |
| RAG responde `modo: "texto"` | Sin `GEMINI_API_KEY`, `COHERE_API_KEY` ni `OPENAI_API_KEY` en el MCP | Configura una y reinicia el contenedor |
| `expected 1536 dimensions` | Modelo de embeddings distinto | Usa `gemini-embedding-001`, `embed-v4.0` o `text-embedding-3-small` con `EMBEDDING_DIM=1536` |
| `flutter pub get` falla por SDK | Flutter < 3.35 | `flutter upgrade` |
| `SocketException` en APK release | Falta `INTERNET` en el manifest | Agrega el permiso y recompila |
| `timeout expired` al conectar | Security Group o red | Verifica salida a internet de la EC2 |

---

## 12. Checklist final de entrega

- [ ] Supabase con los 8 scripts ejecutados y 27 chunks con embedding.
- [ ] `08_actualizar_demo.sql` ejecutado el día de la demo.
- [ ] MCP desplegado con HTTPS y `/health` en `ok`.
- [ ] 18 herramientas del MCP probadas con `test_client.py`.
- [ ] 4 workflows de n8n activos y con credenciales.
- [ ] Los 6 webhooks responden (3 conversacionales + 3 estructurados).
- [ ] APK release compilado con la URL real de n8n.
- [ ] Capturas guardadas en `docs/capturas/` (ver [`capturas/README.md`](capturas/README.md)).
- [ ] Guion del video revisado: [`03-guion-video.md`](03-guion-video.md).

---

## 13. Referencias

- Base de datos: [`../database/README.md`](../database/README.md)
- Servidor MCP: [`../mcp-server/README.md`](../mcp-server/README.md)
- Workflows n8n: [`../n8n/README.md`](../n8n/README.md)
- Pipeline RAG: [`../rag/README.md`](../rag/README.md)
- App Flutter: [`../app/README.md`](../app/README.md)
- Arquitectura: [`01-arquitectura.md`](01-arquitectura.md)
