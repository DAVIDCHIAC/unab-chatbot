# Módulo 2 — Servidor MCP (FastMCP + Docker)

Servidor [MCP](https://modelcontextprotocol.io/) que expone los datos
académicos de la UNAB a los agentes de n8n. Está construido con **FastMCP
1.x**, habla **Streamable HTTP** en `/mcp` y se conecta a **Supabase
(PostgreSQL + pgvector)**.

```
n8n Cloud ──HTTPS/Bearer──> EC2 (Docker) ──psycopg2/SSL──> Supabase
                              └── /mcp      (18 herramientas)
                              └── /health   (healthcheck)
```

---

## 1. Herramientas expuestas

| Grupo | Herramienta | Qué devuelve |
|-------|-------------|--------------|
| Identificación | `identificar_estudiante` | Código UNAB a partir de código, cédula o correo |
| Identificación | `listar_programas` | Programas activos con créditos y semestres |
| Académico | `obtener_estado_academico` | Estado, avance, proyección y alertas en una sola llamada |
| Académico | `obtener_historial` | Historial detallado (filtros por periodo y reprobados) |
| Académico | `obtener_cursos_pendientes` | Asignaturas no aprobadas ni matriculadas |
| Académico | `obtener_prerrequisitos_pendientes` | Cursos bloqueados y el motivo del bloqueo |
| Académico | `proyectar_semestres` | Semestres restantes estimados y fecha de grado |
| Académico | `recomendar_matricula` | Plan de matrícula que respeta prerrequisitos y créditos |
| Académico | `obtener_malla_curricular` | Pensum por programa y semestre |
| Calendario | `consultar_calendario` | Próximos eventos (matrícula, exámenes, pagos…) |
| Calendario | `obtener_periodo_activo` | Periodo vigente con fechas de inicio y fin |
| Noticias | `consultar_noticias` | Convocatorias, becas, eventos y noticias |
| RAG | `buscar_conocimiento_institucional` | Búsqueda vectorial en documentos oficiales |
| RAG | `estadisticas_conocimiento` | Documentos y chunks cargados |
| Soporte | `registrar_conversacion` | Guarda la interacción para auditoría y métricas |
| Soporte | `crear_solicitud` | Crea un caso para Bienestar o Registro Académico |
| Soporte | `consultar_solicitudes` | Solicitudes registradas por un estudiante |
| Soporte | `ping` | Estado del servidor y de la base de datos |

Todas las herramientas devuelven **JSON compacto** (`{"status":"ok", ...}`), lo
que reduce tokens y facilita el trabajo del agente. Son de **solo lectura**
salvo `registrar_conversacion` y `crear_solicitud`.

---

## 2. Estructura

```
mcp-server/
├── server.py              # arranque, Bearer auth, /health, uvicorn
├── app/
│   ├── config.py          # variables de entorno
│   ├── core.py            # instancia FastMCP + seguridad de transporte
│   ├── db.py              # pool psycopg2 y helpers
│   ├── embeddings.py      # embeddings OpenAI, Google Gemini o Cohere
│   ├── utils.py           # JSON, límites, errores
│   └── tools/
│       ├── estudiantes.py
│       ├── academico.py
│       ├── calendario.py
│       ├── noticias.py
│       ├── rag.py
│       └── soporte.py
├── test_client.py         # prueba de humo de las 18 herramientas
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
└── .env.example
```

---

## 3. Requisitos

- Python 3.12 **o** Docker 24+ (recomendado).
- Proyecto de Supabase con los scripts `database/01` … `08` ejecutados.
- (Opcional) `GEMINI_API_KEY` (gratis), `COHERE_API_KEY` (trial gratis) u
  `OPENAI_API_KEY` para búsqueda vectorial real. Sin ninguna, el RAG funciona
  con búsqueda full-text en español.

---

## 4. Configuración

Copia `.env.example` a `.env` y completa los valores:

```bash
cp .env.example .env
```

| Variable | Obligatoria | Descripción |
|----------|-------------|-------------|
| `DB_HOST` | ✅ | Host del **Session pooler** de Supabase |
| `DB_PORT` | ✅ | `5432` (session pooler) |
| `DB_NAME` | ✅ | `postgres` |
| `DB_USER` | ✅ | `postgres.<project-ref>` |
| `DB_PASSWORD` | ✅ | Contraseña de la base de datos |
| `DB_SSLMODE` | ✅ | `require` en Supabase |
| `MCP_API_TOKEN` | recomendado | Token Bearer que exigirá n8n. Vacío = sin auth |
| `MCP_ALLOWED_HOSTS` | ✅ en producción | Hosts permitidos (IP pública, dominio) |
| `MCP_DNS_PROTECTION` | — | `true` por defecto |
| `EMBEDDING_PROVIDER` | — | `openai` \| `gemini` \| `cohere` \| vacío (autodetecta) |
| `GEMINI_API_KEY` | opcional | Embeddings gratis (Google AI Studio) |
| `COHERE_API_KEY` | opcional | Embeddings gratis (trial de Cohere) |
| `OPENAI_API_KEY` | opcional | Embeddings de pago |
| `EMBEDDING_MODEL` | — | `text-embedding-3-small` (OpenAI) |
| `GEMINI_EMBEDDING_MODEL` | — | `gemini-embedding-001` (Gemini) |
| `COHERE_EMBEDDING_MODEL` | — | `embed-v4.0` (Cohere) |
| `EMBEDDING_DIM` | — | `1536` en los tres proveedores |

> **Producción:** el contenedor `unab-mcp` se ejecuta con
> `EMBEDDING_PROVIDER=gemini`, `GEMINI_EMBEDDING_MODEL=gemini-embedding-001` y
> `EMBEDDING_DIM=1536`, igual que `rag/ingest.py`. Así la consulta y la indexación
> usan el mismo modelo. Aunque `OPENAI_API_KEY` existe en el entorno, no se usa
> porque el proveedor está fijado explícitamente.

Genera un token seguro:

```bash
openssl rand -hex 32
```

### Sobre `MCP_ALLOWED_HOSTS`

FastMCP valida el header `Host` para evitar *DNS rebinding*. Si la petición
llega con un host que no está en la lista, responde **421**. Debes incluir
**exactamente** el host con el que n8n llamará al servidor:

```env
# Acceso directo por IP pública
MCP_ALLOWED_HOSTS=localhost:*,127.0.0.1:*,3.15.22.10:9000

# Acceso por dominio con HTTPS (Caddy)
MCP_ALLOWED_HOSTS=localhost:*,127.0.0.1:*,54-211-28-77.sslip.io,54-211-28-77.sslip.io:*
```

> El comodín `*` solo no es válido. Usa `host:*` para cualquier puerto.

---

## 5. Ejecución local

### Opción A — Docker Compose (recomendada)

```bash
docker compose up -d --build
docker compose logs -f
curl http://127.0.0.1:9000/health
```

### Opción B — Python directo

```bash
python -m venv .venv
# Windows: .venv\Scripts\activate
source .venv/bin/activate
pip install -r requirements.txt
python server.py
```

Respuesta esperada de `/health`:

```json
{"status":"ok","service":"UNAB Academic MCP","env":"development","database":"ok"}
```

### Prueba de humo

Con el servidor levantado:

```bash
python test_client.py --url http://127.0.0.1:9000/mcp
# Si definiste MCP_API_TOKEN:
python test_client.py --url http://127.0.0.1:9000/mcp --token TU_TOKEN
```

El cliente lista las herramientas y ejecuta las 18 contra la base de datos.
En Windows, si ves acentos raros en la consola, ejecuta `chcp 65001` antes.

---

## 6. Despliegue en AWS EC2 (paso a paso)

### 6.1 Crear la instancia

1. **EC2 → Launch instance**.
2. Nombre: `unab-mcp`.
3. AMI: **Ubuntu Server 26.04 LTS** (validado en la instancia real; 24.04 LTS también es compatible).
4. Tipo: `t3.micro` (free tier) o `t3.small` si van a correr más servicios.
5. Key pair: crea o selecciona uno (guarda el `.pem`).
6. Security Group (inbound):

| Puerto | Origen | Para qué |
|--------|--------|----------|
| 22 | **Tu IP** | SSH |
| 80, 443 | `0.0.0.0/0` | Caddy: HTTPS y renovación del certificado |

El puerto **9000 no se abre**: `docker-compose.yml` lo publica solo en
`127.0.0.1:9000` y Caddy lo expone por HTTPS en 443. Si prefieres probar sin
dominio, abre 9000 temporalmente y usa `http://TU_IP:9000/mcp` (el token viaja
sin cifrar).

7. Storage: 10–20 GB gp3.
8. Launch.

### 6.2 Instalar Docker

```bash
ssh -i unab-mcp.pem ubuntu@TU_IP_PUBLICA

sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

### 6.3 Subir el proyecto

**Opción git** (si el repo está en GitHub):

```bash
git clone https://github.com/TU_USUARIO/unab-chatbot.git
cd unab-chatbot/mcp-server
```

**Opción scp** (desde tu equipo):

```bash
scp -i unab-mcp.pem -r mcp-server ubuntu@TU_IP_PUBLICA:~/
```

### 6.4 Configurar y arrancar

```bash
cd ~/mcp-server
cp .env.example .env
nano .env
```

Valores mínimos en producción:

```env
APP_ENV=production
DB_HOST=aws-0-us-east-1.pooler.supabase.com
DB_PORT=5432
DB_NAME=postgres
DB_USER=postgres.tuprojectref
DB_PASSWORD=********
DB_SSLMODE=require
MCP_API_TOKEN=<token generado con openssl rand -hex 32>
MCP_ALLOWED_HOSTS=localhost:*,127.0.0.1:*,TU_IP_PUBLICA:9000
# Embeddings: elige uno (Gemini y Cohere tienen cuota gratuita)
GEMINI_API_KEY=AIza...
# COHERE_API_KEY=...
# OPENAI_API_KEY=sk-...
```

```bash
docker compose up -d --build
docker compose ps
curl http://127.0.0.1:9000/health
```

Desde tu equipo:

```bash
curl http://TU_IP_PUBLICA:9000/health
```

### 6.5 Actualizar el servidor

```bash
cd ~/mcp-server
git pull            # o vuelve a subir los archivos con scp
docker compose up -d --build
docker image prune -f
```

### 6.6 Túnel de Cloudflare (sin abrir puertos)

Si el *security group* solo permite SSH y no puedes abrir `80`/`443`, expón el
MCP con un **túnel rápido de Cloudflare**: no requiere cuenta, dominio ni
cambios de firewall, y el contenedor sigue escuchando solo en `127.0.0.1:9000`.

```bash
# 1. cloudflared
curl -fsSL -o /tmp/cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i /tmp/cloudflared.deb

# 2. servicio + temporizador (incluidos en deploy/)
cd ~/unab-chatbot/mcp-server
sudo cp deploy/cloudflared-unab.service /etc/systemd/system/
sudo cp deploy/unab-tunel-sync.service deploy/unab-tunel-sync.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cloudflared-unab.service unab-tunel-sync.timer

# 3. URL pública asignada
grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /home/ubuntu/cloudflared-unab.log | tail -1
```

- `deploy/sync_tunel.sh` lee el hostname del log, lo añade a `MCP_ALLOWED_HOSTS`
  y **solo recrea el contenedor si el host cambió**.
- `unab-tunel-sync.timer` lo ejecuta cada 5 minutos (`OnUnitInactiveSec=5min`),
  así que un reinicio de la instancia no deja el MCP inaccesible.
- El hostname **cambia** cuando cloudflared se reinicia. Tras un cambio:

  ```bash
  python n8n/actualizar_mcp.py https://NUEVO-HOST.trycloudflare.com/mcp
  ```

  y reimporta los workflows (o edita el *Endpoint URL* de los nodos MCP Client).

> Para una URL **fija** (`https://54-211-28-77.sslip.io/mcp`) abre `80` y `443`
> en el security group y usa la opción con Caddy de la sección 7.

---

## 7. HTTPS con Caddy (requiere puertos 80/443)

Un dominio evita enviar el token por HTTP y permite usar el puerto 443.
La forma más rápida es **sslip.io**, que resuelve cualquier nombre con la forma
`IP-CON-GUIONES.sslip.io` a esa IP, sin registrar nada:

```
https://54-211-28-77.sslip.io  →  https://54.211.28.77
```

### 7.1 Despliegue automático (lo que se usó en la EC2 de la demo)

```bash
cd ~/unab-chatbot/mcp-server
./deploy/instalar.sh
```

El script instala Docker + Caddy, construye la imagen, levanta el contenedor,
espera a que `/health` responda y configura Caddy con certificado automático de
Let's Encrypt. Para usar otro dominio:

```bash
DOMINIO=54-211-28-77.sslip.io ./deploy/instalar.sh
# o sin HTTPS, solo el contenedor:
./deploy/instalar.sh --sin-caddy
```

### 7.2 Pasos manuales

1. Instala Caddy (`sudo apt install -y caddy` en Ubuntu 24.04+ o el repositorio
   oficial de Cloudsmith para versiones anteriores).
2. Copia [`deploy/Caddyfile`](deploy/Caddyfile) a `/etc/caddy/Caddyfile` y
   cambia el dominio si hace falta:

```caddyfile
54-211-28-77.sslip.io {
    encode zstd gzip
    reverse_proxy 127.0.0.1:9000
}
```

3. Ajusta `.env` y arranca:

```env
MCP_ALLOWED_HOSTS=localhost:*,127.0.0.1:*,54-211-28-77.sslip.io,54-211-28-77.sslip.io:*
```

```bash
sudo systemctl enable --now caddy
docker compose up -d
curl https://54-211-28-77.sslip.io/health
```

4. En el Security Group deja **80 y 443** abiertos y el **9000 cerrado**: el
   `docker-compose.yml` publica el contenedor solo en `127.0.0.1:9000`, así que
   nadie puede saltarse Caddy.

> Alternativa con dominio propio: crea el subdominio apuntando a la IP
> elástica y usa ese nombre en el `Caddyfile` y en `MCP_ALLOWED_HOSTS`.

---

## 8. Conectar n8n Cloud

1. En n8n abre el workflow y agrega el nodo **AI Agent**.
2. En *Tools* agrega **MCP Client Tool**.
3. Configura:

| Campo | Valor |
|-------|-------|
| Endpoint | `https://TU_TUNEL.trycloudflare.com/mcp` o `https://54-211-28-77.sslip.io/mcp` |
| Server Transport | **HTTP Streamable** |
| Authentication | **Bearer Auth** |
| Bearer Token | el valor de `MCP_API_TOKEN` |
| Tools to include | *All* (o selecciona las que use cada workflow) |

4. Ejecuta el nodo: debe listar las 18 herramientas.

> El workflow **WF03 — Historial y avance** usa este nodo como fuente de
> herramientas. Los workflows 01, 02 y 04 también pueden reutilizarlo.

Prueba rápida desde cualquier máquina con Python:

```bash
pip install "mcp>=1.9"
python test_client.py --url https://TU_ENDPOINT/mcp --token TU_TOKEN
```

---

## 9. Seguridad

- **Nunca** subas `.env` al repositorio (ya está en `.dockerignore`).
- Usa un token largo y distinto por entorno; rótalo si se filtra.
- El contenedor corre como usuario sin privilegios (`uid 10001`).
- El servidor se conecta a Supabase con el usuario `postgres`, que **omite
  RLS**. Es intencional (backend de confianza), pero mantén la contraseña en
  secreto y no la expongas en la app.
- Restringe el puerto 22 a tu IP.
- En producción usa **HTTPS**; el token es la única barrera de acceso.
- `MCP_DNS_PROTECTION=true` evita ataques de DNS rebinding.
- Las herramientas no permiten escribir datos académicos: solo registro de
  conversaciones y solicitudes de soporte.

---

## 10. Problemas frecuentes

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `421 Invalid Host header` | El `Host` no está en `MCP_ALLOWED_HOSTS` | Agrega la IP/dominio exacto y reinicia |
| `401 unauthorized` | Token ausente o distinto | Revisa `MCP_API_TOKEN` y el header `Authorization: Bearer ...` |
| `/health` responde 503 | No hay conexión a Supabase | Revisa credenciales, `DB_SSLMODE=require` y el pooler |
| `password authentication failed` | Usuario mal formado | En Supabase es `postgres.<project-ref>` |
| `timeout expired` al conectar | Security Group / red | Verifica que la EC2 tenga salida a internet |
| `no pg_hba.conf entry` | SSL mal configurado | Usa `DB_SSLMODE=require` |
| RAG devuelve `modo: "texto"` | No hay `GEMINI_API_KEY`, `COHERE_API_KEY` ni `OPENAI_API_KEY` | Es el *fallback* esperado; configura una clave para búsqueda vectorial |
| RAG devuelve 0 resultados | Sin documentos cargados | Ejecuta `database/07_conocimiento_rag.sql` y el pipeline de embeddings |
| Contenedor `unhealthy` | Arrancó antes que la BD | `docker compose logs`; el pool reintenta 5 veces |
| `port is already allocated` | Otro proceso usa 9000 | `sudo lsof -i :9000` o cambia `MCP_PORT` |
| Acentos raros en Windows | Consola cp1252 | `chcp 65001` o `PYTHONIOENCODING=utf-8` |

Logs:

```bash
docker compose logs -f --tail 100
docker inspect --format '{{json .State.Health}}' unab-mcp
```

---

## 11. Variables de entorno completas

| Variable | Default | Descripción |
|----------|---------|-------------|
| `APP_NAME` | `UNAB Academic MCP` | Nombre mostrado en `/health` |
| `APP_ENV` | `development` | `production` para despliegue |
| `LOG_LEVEL` | `INFO` | `DEBUG`, `INFO`, `WARNING`… |
| `DB_HOST` / `DB_PORT` | — / `5432` | Conexión PostgreSQL |
| `DB_NAME` | `postgres` | Base de datos |
| `DB_USER` / `DB_PASSWORD` | `postgres` / — | Credenciales |
| `DB_SSLMODE` | `require` | `disable` solo en local |
| `DB_POOL_MIN` / `DB_POOL_MAX` | `1` / `10` | Tamaño del pool |
| `DB_CONNECT_TIMEOUT` | `10` | Segundos |
| `MCP_HOST` / `MCP_PORT` | `0.0.0.0` / `9000` | Escucha |
| `MCP_PATH` | `/mcp` | Ruta del endpoint |
| `MCP_API_TOKEN` | vacío | Activa Bearer auth si tiene valor |
| `MCP_DNS_PROTECTION` | `true` | Validación de `Host` |
| `MCP_ALLOWED_HOSTS` | `localhost:*,127.0.0.1:*,0.0.0.0:*` | Lista separada por comas |
| `MCP_ALLOWED_ORIGINS` | vacío | Para clientes de navegador |
| `EMBEDDING_PROVIDER` | vacío | `openai` \| `gemini` \| `cohere` \| autodetecta |
| `GEMINI_API_KEY` | vacío | Embeddings gratis de Google AI Studio |
| `GEMINI_EMBEDDING_MODEL` | `gemini-embedding-001` | Modelo Gemini |
| `COHERE_API_KEY` | vacío | Embeddings gratis del trial de Cohere |
| `COHERE_EMBEDDING_MODEL` | `embed-v4.0` | Modelo Cohere |
| `OPENAI_API_KEY` | vacío | Fallback de embeddings (producción usa Gemini) |
| `OPENAI_BASE_URL` | `https://api.openai.com/v1` | Compatible con proxies |
| `EMBEDDING_MODEL` | `text-embedding-3-small` | Modelo OpenAI |
| `EMBEDDING_DIM` | `1536` | Debe coincidir con la columna `vector(1536)` |
| `EMBEDDING_TIMEOUT` | `30` | Segundos |

---

## 12. Estado de validación

Probado el **2026-11-11** con PostgreSQL 16 + pgvector en Docker:

| Prueba | Resultado |
|--------|-----------|
| `python server.py` + `/health` | ✅ `database: ok` |
| `test_client.py` (18 herramientas) | ✅ todas responden `status: ok` |
| Bearer auth | ✅ 401 sin token, 200 con token |
| DNS rebinding | ✅ 421 con `Host` no permitido |
| `docker build` | ✅ imagen `unab-mcp:test` |
| Contenedor + Postgres en red Docker | ✅ `healthy`, 18 herramientas |
| `docker compose config` | ✅ sintaxis válida |

Probado el **2026-11-17** en la EC2 real (`54.211.28.77`, Ubuntu 26.04,
Docker 29.1.3, t3.micro):

| Prueba | Resultado |
|--------|-----------|
| `docker compose build` | ✅ imagen `unab-mcp:latest` (270 MB, 28 s) |
| `/health` dentro del contenedor | ✅ `database: ok` |
| Bearer auth | ✅ `401` sin token |
| `initialize` + `tools/list` | ✅ `UNAB Academic MCP v1.30.0`, **18 herramientas** |
| Herramientas reales (`ping`, `obtener_estado_academico`, `obtener_prerrequisitos_pendientes`, `consultar_calendario`, `consultar_noticias`, `buscar_conocimiento_institucional`, `estadisticas_conocimiento`) | ✅ `status: ok` con datos del estudiante demo `10045234` |
| Contenedor con `mem_limit: 384m` | ✅ estable en t3.micro de 908 MB |
| `caddy validate` del `deploy/Caddyfile` | ✅ configuración válida |

Desplegado en EC2 y verificado desde n8n Cloud: `/health` con `database: ok`, 18 herramientas disponibles por el túnel y 3 agentes consultando el MCP.
