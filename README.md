# Chatbot de Apoyo Académico UNAB

Asistente conversacional para estudiantes de la **Universidad Autónoma de
Bucaramanga** que combina **RAG** sobre documentos institucionales, **agentes con
herramientas MCP** y **consultas estructuradas** al calendario, al historial
académico y a las noticias.

> Proyecto académico de la asignatura **Biing26 · UCC**. Los datos son
> **sintéticos** y el login es demostrativo: no contiene información real de
> estudiantes.
>
> **Repositorio:** <https://github.com/DAVIDCHIAC/unab-chatbot>
>
> **¿Vas a exponer el proyecto?** Usa el
> [**Informe de exposición (3–5 min)**](INFORME_EXPOSICION.md): guion cronometrado,
> tecnologías, demo en vivo, evidencias y preguntas frecuentes.

```
Scraper RSS (WF04 · cron 6 h) ── 2 fuentes + filtros fecha/tema ──┐
                                                                 │
App Flutter (Android)                                            │
        │  HTTPS · JSON                                           │
        ▼                                                         │
n8n Cloud  ── 4 workflows + agentes Gemini + memoria Postgres ◀──┘
        │
        ├── MCP (FastMCP en AWS EC2 · Docker · puerto 9000)
        │        └── 18 herramientas académicas y de RAG
        │
        ├── RAG (rag/ingest.py) ── embeddings Gemini ──┐
        │                                             │
        └── Supabase PostgreSQL 17 + pgvector ◀────────┘ (esquema unab)
```

---

## Tabla de contenido

1. [Qué resuelve](#1-qué-resuelve)
2. [Arquitectura](#2-arquitectura)
3. [Módulos del repositorio](#3-módulos-del-repositorio)
4. [Stack tecnológico](#4-stack-tecnológico)
5. [Arranque rápido](#5-arranque-rápido)
6. [Endpoints](#6-endpoints)
7. [Datos de demostración](#7-datos-de-demostración)
8. [Capturas](#8-capturas)
9. [Video de demostración](#9-video-de-demostración)
10. [Seguridad](#10-seguridad)
11. [Estado de validación](#11-estado-de-validación)
12. [Estructura del repositorio](#12-estructura-del-repositorio)
13. [Documentación](#13-documentación)
14. [Pertinencia pedagógica](#14-pertinencia-pedagógica)
15. [Créditos](#15-créditos)

---

## 1. Qué resuelve

| Necesidad del estudiante | Cómo se atiende | Workflow |
|--------------------------|-----------------|----------|
| «¿Cuáles son los requisitos de grado?» | RAG sobre reglamento, FAQ, grado, becas, bienestar y CCD | WF01 |
| «¿Cuándo son los exámenes finales?» | Consulta del calendario académico | WF02 |
| «¿Cuál es mi avance y qué puedo matricular?» | Herramientas académicas del MCP: historial, prerrequisitos, proyección y recomendación | WF03 |
| «¿Hay becas o convocatorias abiertas?» | Ingesta RSS programada + consulta SQL | WF04 |
| Ver el panorama sin escribir | Pantallas de calendario, avance y noticias con endpoints estructurados | WF02–WF04 |

**Decisiones clave**

- La app **no guarda secretos**: solo conoce la URL de n8n.
- Los tableros usan **endpoints estructurados sin LLM** (rápidos y estables);
  el chat usa agentes con herramientas.
- El **MCP encapsula** las reglas académicas y el acceso a datos, de modo que
  n8n no contiene SQL de negocio.
- El RAG tiene **fallback textual** si no hay embeddings o API key.

---

## 2. Arquitectura

```
┌──────────────────────────────────────────────────────────────┐
│                    App Flutter (Android)                     │
│  Login · Chat RAG · Calendario · Mi avance · Noticias        │
└───────────────────────────┬──────────────────────────────────┘
                            │ HTTPS · POST JSON
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                        n8n Cloud                             │
│  WF01 RAG institucional ── AI Agent ── Gemini 3.5 Flash Lite │
│  WF02 Calendario       ── AI Agent ── Memoria Postgres       │
│  WF03 Académico        ── AI Agent ── 11 herramientas MCP    │
│  WF04 Noticias         ── Cron 6 h + 2 fuentes RSS           │
│  Endpoints estructurados: /calendario/lista, /academico/     │
│  resumen, /noticias                                          │
└───────┬──────────────────────────────────────┬───────────────┘
        │ MCP · HTTP streamable                │ SQL · SSL
        │ Bearer token                         │
        ▼                                      ▼
┌───────────────────────────────┐   ┌──────────────────────────┐
│   FastMCP en AWS EC2          │   │  Supabase PostgreSQL 17  │
│   Docker · puerto 9000        │──▶│  esquema unab            │
│   18 herramientas             │   │  pgvector 1536d · HNSW   │
│   /health · /mcp              │   │  11 vistas analíticas    │
└───────────────┬───────────────┘   └───────────▲──────────────┘
                │ HTTPS                         │ embeddings
                ▼                              │
        ┌───────────────┐        ┌──────────────┴─────────────┐
        │  Gemini API   │        │  Pipeline RAG              │
        │  LLM + embed  │◀───────│  rag/ingest.py             │
        └───────────────┘        │  7 docs → 27 chunks (overlap)│
                                 └────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Scraper RSS (WF04): Google News UNAB + fuente institucional │
│ filtros: últimos 45 días (CURRENT_DATE) + educación /        │
│ tecnología / ingeniería de sistemas → unab.noticias (upsert)  │
└───────────────────────────┬──────────────────────────────────┘
                            └──▶ n8n Cloud / Supabase
```

Detalle completo, flujos y trade-offs en
[`docs/01-arquitectura.md`](docs/01-arquitectura.md).

---

## 3. Módulos del repositorio

| # | Módulo | Carpeta | Contenido | Estado |
|---|--------|---------|-----------|--------|
| 1 | Base de datos | [`database/`](database/) | Esquema `unab`, seed, pgvector, 11 vistas, RLS, demo | ✅ PG16 local y Supabase PG17 |
| 2 | Servidor MCP | [`mcp-server/`](mcp-server/) | FastMCP 1.30, 18 herramientas, Docker, Bearer, `/health` | ✅ Probado en local y Docker |
| 3 | Workflows n8n | [`n8n/`](n8n/) | 4 flujos + 3 endpoints estructurados | ✅ JSON y grafo validados |
| 4 | Pipeline RAG | [`rag/`](rag/) | 7 documentos, chunking con overlap, embeddings, `--reindex`/`--reembed` | ✅ 27/27 chunks en Supabase |
| 5 | App Flutter | [`app/`](app/) | 30 archivos Dart, 7 pantallas, tema UNAB | ✅ Código + APK compilado |
| 6 | Documentación | [`docs/`](docs/) | Arquitectura, despliegue, guion, capturas | ✅ Completa |

---

## 4. Stack tecnológico

| Capa | Tecnología |
|------|------------|
| App móvil | Flutter 3.35+ / Dart 3.9, Material 3, Provider, `http`, `flutter_markdown_plus` |
| Orquestación | n8n Cloud, AI Agent, MCP Client Tool, Postgres Chat Memory |
| LLM | Gemini `gemini-3.5-flash-lite` (temperatura 0.2, clave personal) |
| Servidor MCP | Python 3.12, FastMCP 1.30, psycopg2, Uvicorn, Docker |
| Base de datos | Supabase (PostgreSQL 17), `pgvector`, HNSW cosine |
| Embeddings | Gemini `gemini-embedding-001` (1536 dimensiones en producción; Cohere/OpenAI solo como fallback) |
| Infraestructura | AWS EC2 Ubuntu 26.04, Caddy o Cloudflare Tunnel |
| Seguridad | Bearer token en MCP, validación de `Host`, RLS en Supabase |

---

## 5. Arranque rápido

> Requiere cuentas de Supabase, Gemini (Google AI Studio), AWS y n8n Cloud. La guía detallada está
> en [`docs/02-despliegue.md`](docs/02-despliegue.md).

### 5.1 Base de datos

En el **SQL Editor** de Supabase, ejecuta en orden:

```
database/01_schema.sql
database/02_seed.sql
database/03_rag_pgvector.sql
database/04_vistas.sql
database/05_rls_policies.sql
database/06_consultas_demo.sql        (opcional)
database/07_conocimiento_rag.sql
database/08_actualizar_demo.sql
```

O aplica todo de una vez con el script incluido (recomendado, valida conteos al
final y detecta Supabase automáticamente):

```bash
python -m pip install psycopg2-binary
python database/aplicar_todo.py "postgresql://postgres.PROYECTO:PASSWORD@aws-0-region.pooler.supabase.com:5432/postgres"
```

Antes de cada demo, refresca fechas con `python database/aplicar_todo.py --only 08 --yes`.

### 5.2 Embeddings del RAG

```bash
cd rag
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env             # DATABASE_URL + GEMINI_API_KEY (o COHERE_API_KEY)
python ingest.py --reembed
python ingest.py --stats
```

### 5.3 Servidor MCP

```bash
cd mcp-server
cp .env.example .env             # Supabase, token y clave de embeddings (opcional)
docker compose up -d --build
curl http://127.0.0.1:9000/health
python test_client.py --url http://127.0.0.1:9000/mcp --token <TOKEN>
```

Despliegue en EC2 + HTTPS: [`mcp-server/README.md`](mcp-server/README.md).

### 5.4 n8n

1. Importa los 4 JSON de [`n8n/`](n8n/).
2. Crea 3 credenciales: **Postgres** (Supabase), **Bearer Auth** (MCP) y **Google Gemini(PaLM) API** (clave personal).
3. En la credencial Postgres: SSL **Require**, **Ignore SSL Issues (Insecure) = ON** y **SSH Tunnel = OFF**.
4. Asigna el endpoint `https://<tunnel>.trycloudflare.com/mcp` en los 3 nodos MCP Client.
5. Publica los 4 workflows.

Detalle: [`n8n/README.md`](n8n/README.md). Si usas el **plan Free Trial** (sin
API pública de n8n), sigue la guía paso a paso
[`n8n/CONFIGURACION_MANUAL.md`](n8n/CONFIGURACION_MANUAL.md).

### 5.5 App Flutter

La carpeta `android/` y el permiso `INTERNET` ya están incluidos; solo necesitas
Flutter 3.35+ y un dispositivo/emulador:

```bash
cd app
flutter pub get
flutter test
flutter run --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
```

APK release:

```bash
flutter build apk --release --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

> Si borras `android/`, regéneralo con
> `flutter create --platforms=android --org co.edu.unab --project-name unab_chatbot .`

Detalle: [`app/README.md`](app/README.md).

---

## 6. Endpoints

Base: `https://<tu-instancia>.app.n8n.cloud`

| Método | Ruta | Uso | LLM |
|--------|------|-----|-----|
| POST | `/webhook/unab/rag` | Chat institucional (RAG) | Sí |
| POST | `/webhook/unab/calendario` | Chat de calendario | Sí |
| POST | `/webhook/unab/calendario/lista` | Listado para la pantalla de calendario | No |
| POST | `/webhook/unab/academico` | Chat de historial y avance | Sí |
| POST | `/webhook/unab/academico/resumen` | Resumen para la pantalla académica | No |
| POST | `/webhook/unab/noticias` | Noticias y convocatorias (estructurado) | No |

Ejemplo:

```bash
curl -X POST "https://TU-INSTANCIA.app.n8n.cloud/webhook/unab/rag" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"ses-001","pregunta":"¿Cuáles son los requisitos de grado?"}'
```

```json
{
  "ok": true,
  "session_id": "ses-001",
  "tipo": "rag",
  "respuesta": "Para obtener el título debes ...",
  "latencia_ms": 4210
}
```

Contratos completos en [`n8n/README.md`](n8n/README.md#4-endpoints-y-payloads).

### Servidor MCP

| Ruta | Descripción |
|------|-------------|
| `GET /health` | Estado del servidor y de la base de datos |
| `POST /mcp` | Endpoint Streamable HTTP con las 18 herramientas |

Herramientas: identificación, estado académico, historial, cursos pendientes,
prerrequisitos, proyección, recomendación de matrícula, malla curricular,
calendario, periodo activo, noticias y búsqueda de conocimiento institucional.

---

## 7. Datos de demostración

| Código | Nombre | Semestre | Caso |
|--------|--------|----------|------|
| **`10045234`** | **Jhon García** | **3** | **Caso estrella:** reprobó Cálculo Integral (`IS201`, nota 2.4) → Cálculo Multivariado (`IS301`) bloqueado |
| `10045231` | Laura Martínez | 9 | Avance alto (87%), cerca del grado |
| `10045232` | Carlos Rodríguez | 7 | Una reprobación aleatoria |
| `10045235` | María Hernández | 1 | Estudiante nueva, sin historial |
| `10045236` | Luis Torres | 10 | Último semestre, 92% de avance |
| `10045260` | Simón Molina | 2 | Semestre temprano |

Volumen de datos: **12 programas**, **51 cursos**, **37 prerrequisitos**,
**30 estudiantes**, **908 filas de historial**, **20 noticias**,
**7 documentos RAG** y **27 chunks** con embedding. Conteos verificados en
[`database/evidencias/verificacion_supabase.txt`](database/evidencias/verificacion_supabase.txt).

> Las fechas del calendario y las noticias son relativas a `CURRENT_DATE`.
> Ejecuta `database/08_actualizar_demo.sql` antes de cada demo.

---

## 8. Capturas

Las imágenes viven en [`docs/capturas/`](docs/capturas/) con esta convención:

| Archivo | Contenido | Vista |
|---------|-----------|-------|
| `01-login.png` | Pantalla de identificación con el botón del estudiante demo | <img src="docs/capturas/01-login.png" width="170" alt="Login UNAB"> |
| `02-chat.png` | Chat con respuesta RAG y fuente citada | <img src="docs/capturas/02-chat.png" width="170" alt="Chat RAG"> |
| `03-calendario.png` | Calendario filtrado por *Exámenes* | <img src="docs/capturas/03-calendario.png" width="170" alt="Calendario"> |
| `04-academico.png` | Avance, alertas y cursos bloqueados | <img src="docs/capturas/04-academico.png" width="170" alt="Avance académico"> |
| `05-noticias.png` | Noticias filtradas por *Becas* | <img src="docs/capturas/05-noticias.png" width="170" alt="Noticias"> |
| `06-n8n.png` | Workflow WF01 abierto en n8n | <img src="docs/capturas/06-n8n.png" width="170" alt="Workflow n8n"> |
| `07-mcp.png` | Respuesta de `/health` del servidor MCP | <img src="docs/capturas/07-mcp.png" width="170" alt="Health MCP"> |

Guía de captura: [`docs/capturas/README.md`](docs/capturas/README.md).

> Capturas `01`–`05` tomadas en el emulador `Pixel_8_Pro` (1344×2992), `06` en la
> sesión de n8n Cloud del autor (1435×633) y `07` en el servidor MCP de producción.
> Las 7 imágenes son PNG válidos y están enlazadas desde este README.

---

## 9. Video de demostración

Guion escena por escena (8–10 min): [`docs/03-guion-video.md`](docs/03-guion-video.md).

> Enlace del video publicado: **_(pendiente)_**

---

## 10. Seguridad

| Capa | Control implementado |
|------|----------------------|
| App | Sin secretos; solo la URL de n8n inyectada en compilación |
| n8n | Credenciales cifradas; webhooks públicos **solo para la demo** |
| MCP | `Authorization: Bearer <token>` + validación de `Host` (DNS rebinding) |
| Red | Caddy con TLS; Security Group limitado a 22/80/443 |
| Base de datos | RLS para clientes Supabase; backend con usuario de servicio |
| Datos | Sintéticos; sin PII real en el repositorio |

**Antes de producción:**

1. Activa Header Auth en los 4 webhooks y envía el header desde la app.
2. Integra Supabase Auth y deriva el `id_estudiante` del JWT.
3. Rota el token del MCP y la llave de Gemini.
4. Restringe CORS y configura backups y alertas.
5. Revisa la retención de `unab.conversaciones`.

Nunca subas `.env`, `.pem`, keystores ni llaves al repositorio.

---

## 11. Estado de validación

| Componente | Prueba | Resultado |
|------------|--------|-----------|
| Base de datos | 8 scripts en Supabase (PostgreSQL 17) + pgvector | ✅ 51 cursos, 30 estudiantes, 908 historial, 27 chunks |
| Vistas | 11 vistas analíticas | ✅ Datos coherentes para `10045234` |
| MCP | 18 herramientas con `test_client.py` | ✅ Todas `status: ok` |
| MCP | Bearer auth y DNS rebinding | ✅ 401 sin token / 421 host inválido |
| MCP | Desplegado en EC2 + Docker contra Supabase | ✅ `/health` → `database: ok` |
| MCP | Llamadas externas por el túnel (como n8n Cloud) | ✅ 18 tools + 9 llamadas reales |
| RAG | 27 chunks con `gemini-embedding-001` (overlap 160) | ✅ `con_embedding: 27`, modelo homogéneo |
| RAG | `buscar_conocimiento_institucional` | ✅ `modo: "vectorial"`, scores 0.58–0.68 en la pregunta de ejemplo |
| n8n | JSON, nombres, conexiones y ramas IF | ✅ 4 workflows válidos |
| n8n | Importados en `unab-chatbot.app.n8n.cloud` vía MCP | ✅ 61 nodos, 54 conexiones |
| n8n | Credenciales + publicación + 6 webhooks | ✅ 3 credenciales asignadas; 4/4 workflows activos |
| App | Estructura Dart (30 archivos) | ✅ 0 problemas de sintaxis/balance |
| App | `flutter analyze` / `flutter test` | ✅ 0 errores; 7/7 pruebas |
| App | `flutter build apk --release` | ✅ APK 50.7 MB (Flutter 3.50.0) |
| End-to-end | 6 webhooks (3 agentes + 3 endpoints) | ✅ 6/6 HTTP 200 con respuestas reales (22/11) |
| Scraper RSS | 2 fuentes + filtros fecha/tema + upsert | ✅ ejecución `100` exitosa: 9 + 27 ítems → 6 noticias válidas |
| RAG | pregunta → 5 fragmentos con scores | ✅ 27/27 chunks con `gemini:gemini-embedding-001`, overlap 160 |

### Evidencia almacenada en el repositorio

| Archivo | Qué demuestra |
|---------|---------------|
| [`database/evidencias/verificacion_supabase.txt`](database/evidencias/verificacion_supabase.txt) | Conteos reales (12 programas, 51 cursos, 30 estudiantes, 908 historial, 27 chunks), caso `10045234`, recuperación vectorial y `EXPLAIN ANALYZE` del índice HNSW |
| [`database/evidencias/respuesta_personalizada.json`](database/evidencias/respuesta_personalizada.json) | Respuesta del WF03 al caso estrella **guardada** en `unab.conversaciones`, con su sesión, latencia y contexto |
| [`n8n/evidencias/respuestas_webhooks.json`](n8n/evidencias/respuestas_webhooks.json) | Los 6 payloads y sus respuestas HTTP 200 completas |
| [`n8n/evidencias/README.md`](n8n/evidencias/README.md) | Resumen legible de la pasada de webhooks |
| [`n8n/evidencias/ejecucion_scraper.json`](n8n/evidencias/ejecucion_scraper.json) | Ejecución real del cron: 2 fuentes RSS, filtros por `CURRENT_DATE` y temas, y 6 filas insertadas |
| [`rag/evidencias/recuperacion_ejemplo.json`](rag/evidencias/recuperacion_ejemplo.json) | Pregunta real → 5 fragmentos con similitudes y homogeneidad del modelo de embeddings |

Detalle técnico del RAG: [`docs/04-rag-detalle.md`](docs/04-rag-detalle.md).

---

## 12. Estructura del repositorio

```
unab-chatbot/
├── README.md                     # este archivo
├── .gitignore                    # secretos, entornos y artefactos
├── docs/
│   ├── 00-plan.md                # plan y estado de entregables
│   ├── 01-arquitectura.md        # componentes, flujos, decisiones
│   ├── 02-despliegue.md          # guía paso a paso
│   ├── 03-guion-video.md         # guion de la demo
│   ├── 04-rag-detalle.md         # decisión técnica del RAG + evidencia
│   ├── MANUAL_USUARIO.md         # guía para el estudiante
│   └── capturas/                 # screenshots del informe
│       └── README.md             # convención y guía de captura
├── database/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_rag_pgvector.sql
│   ├── 04_vistas.sql
│   ├── 05_rls_policies.sql
│   ├── 06_consultas_demo.sql
│   ├── 07_conocimiento_rag.sql
│   ├── 08_actualizar_demo.sql
│   ├── aplicar_todo.py            # aplica 01..08 en orden y verifica
│   ├── evidencias/
│   │   ├── verificacion_supabase.txt
│   │   └── respuesta_personalizada.json
│   └── README.md
├── mcp-server/
│   ├── server.py
│   ├── app/
│   ├── test_client.py
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md
├── n8n/
│   ├── wf01_rag_institucional.json
│   ├── wf02_calendario.json
│   ├── wf03_historial_mcp.json
│   ├── wf04_noticias.json
│   ├── evidencias/
│   │   ├── respuestas_webhooks.json
│   │   ├── README.md
│   │   └── ejecucion_scraper.json
│   └── README.md
├── rag/
│   ├── documentos/               # 7 Markdown con front matter
│   ├── evidencias/
│   │   └── recuperacion_ejemplo.json
│   ├── ingest.py
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
└── app/
    ├── lib/                      # 30 archivos Dart
    ├── test/widget_test.dart     # 7 pruebas de modelos y json_utils
    ├── android/                  # proyecto Android (co.edu.unab.unab_chatbot)
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── .gitignore
    └── README.md
```

---

## 13. Documentación

| Documento | Contenido |
|-----------|-----------|
| [`INFORME_EXPOSICION.md`](INFORME_EXPOSICION.md) | **Versión resumida para exponer en 3–5 min** (guion, demo, evidencias) |
| [`docs/00-plan.md`](docs/00-plan.md) | Entregables, decisiones y estado |
| [`docs/01-arquitectura.md`](docs/01-arquitectura.md) | Diseño, diagramas, modelo de datos, seguridad |
| [`docs/02-despliegue.md`](docs/02-despliegue.md) | Supabase, Gemini, RAG, EC2, n8n, Flutter |
| [`docs/03-guion-video.md`](docs/03-guion-video.md) | Guion de la demo y checklist de grabación |
| [`docs/04-rag-detalle.md`](docs/04-rag-detalle.md) | Chunking, overlap, modelo único y evidencia de recuperación |
| [`docs/MANUAL_USUARIO.md`](docs/MANUAL_USUARIO.md) | Guía paso a paso para el estudiante demo |
| [`database/README.md`](database/README.md) | Scripts, orden, estudiantes de prueba |
| [`mcp-server/README.md`](mcp-server/README.md) | Herramientas, Docker, EC2, Caddy |
| [`n8n/README.md`](n8n/README.md) | Importación, credenciales, endpoints, troubleshooting |
| [`n8n/CONFIGURACION_MANUAL.md`](n8n/CONFIGURACION_MANUAL.md) | Credenciales paso a paso para el plan Free Trial |
| [`rag/README.md`](rag/README.md) | Pipeline, comandos y verificación |
| [`app/README.md`](app/README.md) | Requisitos, build, contratos y demo |

---

## 14. Pertinencia pedagógica

El proyecto no es solo un chatbot de preguntas frecuentes: es un **entorno de
apoyo al autoaprendizaje** que implementa una forma modesta de *educación de
precisión*. En lugar de dar la misma respuesta a todos, el WF03 combina:

1. **Datos granulares del estudiante**: semestre, promedio, créditos aprobados,
   historial, prerrequisitos y alertas (`v_avance_plan`, `v_alertas_academicas`).
2. **Conocimiento institucional recuperado por RAG** (reglamento, plan de
   estudios, requisitos de grado).
3. **Una recomendación accionable** que se guarda en `unab.conversaciones` junto
   con la pregunta, la sesión, el canal y la latencia.

### Caso estrella

Para `10045234` (Jhon García, 3.er semestre, promedio 3.69, 18.8 % de avance),
el sistema detecta que reprobó **Cálculo Integral (IS201, nota 2.4)**, infiere
que **Cálculo Multivariado (IS301)** está bloqueado y recomienda recuperar IS201
antes de matricular. La respuesta completa quedó persistida y se puede auditar
en [`database/evidencias/respuesta_personalizada.json`](database/evidencias/respuesta_personalizada.json).

Esto traslada al estudiante parte del control del proceso —consultar,
comprender y decidir su malla— sin sustituir la orientación del director de
programa, que aparece explícitamente en la recomendación.

### Fundamentación

| Referencia | Aporte al diseño |
|------------|------------------|
| Knowles (1975), *Self-directed learning* | El estudiante asume responsabilidad de su aprendizaje; el bot le entrega información oportuna para decidir. |
| Zimmerman (2002), *Becoming a self-regulated learner* | La retroalimentación inmediata (avance, bloqueos, proyección) apoya la autorregulación: planificar, monitorear y ajustar. |
| Siemens (2005), *Connectivism* | El conocimiento se reparte entre fuentes (BD, RAG, RSS, agente); la competencia clave es saber conectarse a esas fuentes. |
| UNESCO (2023), *GEM Report: Technology in education* | Advierte que la tecnología debe estar al servicio de la equidad y del docente; por eso los datos son sintéticos y la recomendación no reemplaza al orientador. |

Referencias completas:

- Knowles, M. S. (1975). *Self-directed learning: A guide for learners and teachers*. Association Press.
- Zimmerman, B. J. (2002). Becoming a self-regulated learner: An overview. *Theory Into Practice, 41*(2), 64–70. <https://doi.org/10.1207/s15430421tip4102_2>
- Siemens, G. (2005). Connectivism: A learning theory for the digital age. *International Journal of Instructional Technology and Distance Learning, 2*(1), 3–10. <http://www.itdl.org/Journal/Jan_05/article01.htm>
- UNESCO (2023). *Global Education Monitoring Report 2023: Technology in education – A tool on whose terms?* <https://unesdoc.unesco.org/ark:/48223/pf0000385723>

---

## 15. Créditos

- **Repositorio:** <https://github.com/DAVIDCHIAC/unab-chatbot>.
- **Asignatura:** Biing26 · Universidad Cooperativa de Colombia (UCC).
- **Institución de estudio de caso:** Universidad Autónoma de Bucaramanga (UNAB).
- **Inspiración:** repositorio de referencia del Centro de Competencias
  Digitales (CCD) UNAB.
- **Datos:** sintéticos y generados con scripts deterministas.

> Este proyecto es académico y no representa oficialmente a la UNAB. Las URLs,
> nombres y datos institucionales son ilustrativos.
