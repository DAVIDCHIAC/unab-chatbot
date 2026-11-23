# Arquitectura — Chatbot de Apoyo Académico UNAB

Documento de diseño del sistema: componentes, flujos, modelo de datos,
decisiones técnicas y límites del alcance.

---

## 1. Resumen ejecutivo

El sistema es un **asistente académico conversacional** para estudiantes de la
Universidad Autónoma de Bucaramanga (UNAB), acompañado de tres tableros de
consulta rápida (calendario, avance académico y noticias).

| Capacidad | Cómo se resuelve |
|-----------|------------------|
| Dudas sobre reglamento, trámites, grado, becas y bienestar | RAG sobre documentos institucionales (`pgvector`) |
| Fechas de matrícula, exámenes y pagos | Consulta SQL del calendario académico |
| Historial, avance, prerrequisitos y recomendación de matrícula | Herramientas académicas del servidor MCP |
| Noticias y convocatorias | Ingesta RSS programada + consulta SQL |
| Interfaz para el estudiante | App Flutter (Android) |

Principios de diseño:

1. **La app no conoce secretos.** No tiene llaves de Gemini, contraseña de
   Supabase ni token del MCP. Solo habla HTTPS con n8n.
2. **Una responsabilidad por componente.** n8n orquesta, el MCP encapsula el
   acceso a datos y reglas académicas, Supabase almacena, la app presenta.
3. **Respuestas deterministas donde importa.** Los tableros usan endpoints
   estructurados (SQL directo) para no depender del LLM ni gastar tokens.
4. **Datos sintéticos y reproducibles.** El pensum, los estudiantes y el
   historial se generan con scripts idempotentes.
5. **Degradación controlada.** Si no hay embeddings o API key, el RAG usa
   búsqueda textual; si un workflow falla, la app muestra un error accionable.

---

## 2. Vista de componentes

```
┌──────────────────────────────────────────────────────────────┐
│                    App Flutter (Android)                     │
│  Login · Chat RAG · Calendario · Mi avance · Noticias        │
└───────────────────────────┬──────────────────────────────────┘
                            │ HTTPS · POST JSON
                            │ (sin secretos en el cliente)
                            ▼
┌──────────────────────────────────────────────────────────────┐
│                        n8n Cloud                             │
│                                                              │
│  WF01 RAG institucional ── AI Agent ── Gemini Chat Model     │
│  WF02 Calendario       ── AI Agent ── Memoria Postgres       │
│  WF03 Académico        ── AI Agent ── 11 herramientas MCP    │
│  WF04 Noticias         ── Cron 6 h · 2 fuentes RSS          │
│                                                              │
│  Endpoints estructurados: /calendario/lista, /academico/     │
│  resumen, /noticias (sin LLM)                                │
└───────────────┬──────────────────────────────┬───────────────┘
                │ MCP · HTTP streamable        │ SQL (pg)
                │ Bearer token                 │ SSL
                ▼                              ▼
┌───────────────────────────────┐   ┌──────────────────────────┐
│   FastMCP en AWS EC2          │   │  Supabase PostgreSQL 17  │
│   Docker · puerto 9000        │──▶│  esquema unab            │
│   18 herramientas             │   │  pgvector 1536d · HNSW   │
│   /health · /mcp              │   │  11 vistas analíticas    │
└───────────────┬───────────────┘   └───────────▲──────────────┘
                │ HTTPS                         │ embeddings
                ▼                              │
        ┌───────────────┐        ┌──────────────┴─────────────┐
        │  Gemini API   │        │  Pipeline RAG (local)      │
        │  LLM + embed  │◀───────│  rag/ingest.py             │
        └───────────────┘        │  7 docs → 27 chunks (overlap)│
                                 └────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Scraper RSS (WF04): Google News UNAB + fuente institucional │
│ Filtros: últimos 45 días (CURRENT_DATE) + educación /         │
│ tecnología / ingeniería de sistemas → unab.noticias (upsert)  │
└───────────────────────────┬──────────────────────────────────┘
                            └──▶ n8n Cloud / Supabase
```

### 2.1 Componentes y responsabilidades

| Componente | Tecnología | Responsabilidad | Dónde vive |
|------------|------------|-----------------|------------|
| App móvil | Flutter 3.35+ / Dart 3.9 | UI, sesión local, consumo de webhooks, Markdown y enlaces | APK Android |
| Orquestador | n8n Cloud | Webhooks, agentes, memoria, cron RSS, formateo de respuestas | n8n Cloud |
| Servidor MCP | Python 3.12 + FastMCP 1.30 + psycopg2 | 18 herramientas de negocio y RAG, validación de entrada, pooling | EC2 + Docker |
| Base de datos | Supabase (PostgreSQL 17 + pgvector) | Datos académicos, calendario, noticias, conversaciones, vectores | Supabase |
| LLM | Gemini `gemini-3.5-flash-lite` | Comprensión de la pregunta y redacción de la respuesta | Clave personal de Google AI Studio |
| Embeddings | Gemini `gemini-embedding-001` (Cohere/OpenAI como fallback) | Vectores de 1536 dimensiones para el RAG | API externa |
| Ingesta RAG | Python + `psycopg2` | Chunking, embeddings, upsert idempotente | Local / CI |
| TLS | Caddy + sslip.io o Cloudflare Tunnel | HTTPS para el endpoint MCP | EC2 |
| Memoria | Postgres (`unab_chat_memory`) | Contexto de conversación por `session_id` | Supabase (esquema `public`) |

---

## 3. Flujo de una consulta RAG (WF01)

```
Estudiante          App              n8n WF01            MCP               Supabase
    │                │                  │                 │                   │
    │ pregunta       │                  │                 │                   │
    ├───────────────▶│ POST /unab/rag   │                 │                   │
    │                ├─────────────────▶│ normaliza       │                   │
    │                │                  │ agente decide   │                   │
    │                │                  ├────────────────▶│ buscar_conocimiento│
    │                │                  │                 ├──────────────────▶│
    │                │                  │                 │◀──────────────────┤
    │                │                  │◀────────────────┤ chunks + fuentes  │
    │                │                  │ Gemini redacta  │                   │
    │                │                  │ registra log    │                   │
    │                │◀─────────────────┤ {respuesta,     │                   │
    │◀───────────────┤                  │  latencia_ms}   │                   │
    │ Markdown       │                  │                 │                   │
```

Puntos clave:

- El **agente** decide qué herramienta usar según la pregunta. No hay
  enrutamiento rígido por palabras clave.
- El **MCP** valida y limita los parámetros antes de tocar la base de datos.
- La **respuesta** se devuelve en JSON y la app la renderiza como Markdown
  (los enlaces se abren en el navegador).
- La conversación se registra en `unab.conversaciones` para métricas
  (`unab.v_kpis_chatbot`).

---

## 4. Los cuatro workflows

| WF | Ruta conversacional | Ruta estructurada | Herramientas MCP |
|----|---------------------|-------------------|------------------|
| 01 | `POST /webhook/unab/rag` | — | `buscar_conocimiento_institucional`, `consultar_calendario`, `obtener_periodo_activo`, `consultar_noticias`, `identificar_estudiante`, `obtener_estado_academico`, `obtener_historial`, `obtener_prerrequisitos_pendientes`, `recomendar_matricula` |
| 02 | `POST /webhook/unab/calendario` | `POST /webhook/unab/calendario/lista` | `consultar_calendario`, `obtener_periodo_activo` |
| 03 | `POST /webhook/unab/academico` | `POST /webhook/unab/academico/resumen` | 11 herramientas académicas y de identificación |
| 04 | `POST /webhook/unab/noticias` | misma ruta, respuesta estructurada | — (SQL + RSS) |

### 4.1 Por qué dos tipos de endpoint

| | Conversacional | Estructurado |
|---|---|---|
| Usa LLM | Sí | No |
| Latencia típica | 3–12 s | 0.2–1 s |
| Costo por consulta | Tokens de entrada/salida | Solo cómputo de BD |
| Salida | Texto Markdown | JSON tipado para widgets |
| Uso | Chat, preguntas abiertas | Tableros, listados, filtros |

Los tableros necesitan datos estables y rápidos; el chat necesita lenguaje
natural. Separarlos evita que un fallo del LLM deje la app sin calendario o sin
noticias.

---

## 5. Modelo de datos

### 5.1 Tablas principales (`unab`)

| Tabla | Propósito |
|-------|-----------|
| `programas` | Catálogo de programas, créditos y semestres |
| `cursos` | Pensum por programa y semestre |
| `prerrequisitos` | Relación curso → prerrequisito |
| `estudiantes` | Datos del estudiante, programa, semestre y promedio |
| `historial_academico` | Cursos cursados, periodo, nota, estado e intento |
| `periodos_academicos` | Periodos con fecha de inicio y fin |
| `calendario_academico` | Eventos públicos (matrícula, exámenes, pagos…) |
| `noticias` | Noticias, becas y convocatorias con URL y categoría |
| `conversaciones` | Auditoría de preguntas, respuestas, tipo y latencia |
| `solicitudes` | Casos creados para Bienestar o Registro Académico |
| `documentos` | Catálogo de fuentes del RAG |
| `documentos_vectoriales` | Chunks + `embedding vector(1536)` + metadatos |

### 5.2 Vistas analíticas

Las vistas concentran joins y reglas para que el agente haga **una sola
llamada** por consulta:

| Vista | Contenido |
|-------|-----------|
| `v_estado_estudiante` | Estado, promedio, cursos y créditos aprobados/en curso |
| `v_avance_plan` | Créditos aprobados vs. totales y porcentaje de avance |
| `v_proyeccion_semestres` | Ritmo, semestres restantes y semestre de grado |
| `v_historial_detalle` | Historial con nombre de curso, área y docente |
| `v_cursos_pendientes` | Cursos no aprobados ni matriculados |
| `v_prerrequisitos_pendientes` | Cursos bloqueados y motivo del bloqueo |
| `v_alertas_academicas` | Riesgo por promedio, reprobaciones y bloqueos |
| `v_calendario_proximo` | Eventos vigentes/futuros con días faltantes |
| `v_noticias_recientes` | Noticias activas con días desde publicación |
| `v_malla_curricular` | Pensum con prerrequisitos consolidados |
| `v_kpis_chatbot` | Uso, latencia y feedback del chatbot |

### 5.3 Relaciones

```
programas ──< cursos ──< prerrequisitos
    │            │
    └──< estudiantes ──< historial_academico >── cursos
              │
              ├──< conversaciones
              ├──< solicitudes
              ├──< notificaciones
              └──< dispositivos

periodos_academicos ──< calendario_academico
noticias
documentos ──> documentos_vectoriales (pgvector 1536d)
```

### 5.4 Compatibilidad con n8n

`unab.documentos_vectoriales` usa las columnas que espera el nodo
**Postgres PGVector Store** de n8n (`id`, `content`, `metadata`, `embedding`).
Aunque WF01 usa la herramienta MCP para recuperar contexto, la tabla queda lista
para flujos nativos o para una migración futura.

---

## 6. Diseño del RAG

### 6.1 Corpus

| Documento | Tema |
|-----------|------|
| `reglamento_estudiantil.md` | Derechos, deberes, evaluación, cancelación |
| `faq_academica.md` | Trámites frecuentes, horarios, contactos |
| `proceso_grado.md` | Requisitos, modalidades, pasos y tiempos |
| `becas_monitorias.md` | Becas, monitorías, requisitos y fechas |
| `bienestar_universitario.md` | Servicios de bienestar y acompañamiento |
| `ccd_competencias_digitales.md` | Centro de Competencias Digitales |
| `plan_estudios_ingenieria_sistemas.md` | Malla, créditos, prerrequisitos y grado |

Cada archivo tiene *front matter* (título, fuente, URL, categoría, versión) y
se divide en **27 chunks** de 40 a 1400 caracteres con 160 de solapamiento.

### 6.2 Pipeline

```
documentos/*.md
   │  parse front matter + secciones
   ▼
chunks (23)
   │  Gemini (producción, batch 64)
   ▼
unab.documentos_vectoriales
   │  índice HNSW (cosine)
   ▼
buscar_conocimiento(query_embedding, top_k)
```

El script `rag/ingest.py` es **idempotente por fuente**: borra y recarga los
chunks del documento, actualiza el catálogo en `unab.documentos` y permite
`--reindex`, `--reembed`, `--dry-run`, `--stats`, `--file` y `--limit`.

### 6.3 Recuperación

La herramienta `buscar_conocimiento_institucional`:

1. Genera el embedding de la consulta (si hay `GEMINI_API_KEY`,
   `COHERE_API_KEY` u `OPENAI_API_KEY`).
2. Ejecuta la función SQL `unab.buscar_conocimiento` con similitud coseno.
3. Si no hay embeddings o la API falla, cae a búsqueda textual
   (`ILIKE`/`tsvector`) para no romper la demo.
4. Devuelve chunks, título, fuente, URL y score.

### 6.4 Por qué el RAG vive en el MCP y no en un nodo de n8n

- Funciona **antes** de generar embeddings (fallback textual).
- Centraliza el prompt de recuperación y los límites (`top_k`, longitud).
- Evita duplicar lógica entre workflows.
- Permite probar la recuperación con `test_client.py` sin abrir n8n.

---

## 7. Diseño de los agentes

| Parámetro | Valor | Razón |
|-----------|-------|-------|
| Modelo | `gemini-3.5-flash-lite` | Buen equilibrio costo/calidad para la demo |
| Temperatura | `0.2` | Respuestas consistentes y apegadas a los datos |
| Memoria | Postgres (`unab_chat_memory`) | Contexto multi-turno por `session_id` |
| Herramientas | MCP Client Tool (`httpStreamable`) | Un solo endpoint para todas las tools |
| Timeout | 60 s en el nodo MCP; 90 s en la app | Margen para cold start de n8n/Gemini |
| Formato | Markdown | La app lo renderiza con `flutter_markdown_plus` |

Cada workflow tiene un *system message* que define rol, límites y tono. El
agente debe:

1. Usar herramientas antes de inventar datos.
2. Citar la fuente cuando responda con RAG.
3. Pedir el código del estudiante si la pregunta requiere datos personales.
4. No revelar información de otros estudiantes.
5. Responder en español, con bullets y fechas en formato local.

---

## 8. Seguridad

### 8.1 Capas

| Capa | Control |
|------|---------|
| Cliente | Sin secretos; solo URL de n8n inyectada en compilación |
| n8n | Credenciales cifradas; webhooks públicos en demo (Header Auth recomendado en producción) |
| MCP | `Authorization: Bearer <token>` + validación de `Host` (DNS rebinding) |
| Red | Caddy con TLS; Security Group solo 22/80/443 |
| Base de datos | RLS para usuarios de Supabase; backend con credenciales de servicio |
| Datos | Sintéticos; sin PII real en el repositorio |

### 8.2 Riesgos y mitigaciones

| Riesgo | Mitigación |
|--------|------------|
| Webhook público permite consultar por código | Validar identidad con Supabase Auth en producción; limitar rate limit en n8n/API Gateway |
| Token del MCP en texto plano | HTTPS obligatorio; rotar token; no exponer 9000 |
| Inyección SQL | Consultas parametrizadas en MCP y en nodos Postgres (`$1`, `$2`) |
| Fuga de API keys | `.env` fuera de Git; credenciales de n8n; nunca en la app |
| Alucinaciones del LLM | Temperatura baja, herramientas obligatorias, datos en las vistas |
| Costos descontrolados | `gemini-3.5-flash-lite`, límites de `top_k`, endpoints estructurados sin LLM |

### 8.3 Producción

Antes de un despliegue real:

1. Activar **Header Auth** en los 4 webhooks y enviar el header desde la app.
2. Integrar **Supabase Auth** y derivar el `id_estudiante` del JWT, no del body.
3. Rotar el token del MCP y las llaves de Gemini.
4. Restringir CORS (`allowedOrigins`) a los orígenes reales.
5. Configurar backups y alertas de Supabase.
6. Revisar la política de retención de `unab.conversaciones`.

---

## 9. Despliegue y topología

| Entorno | Base de datos | MCP | n8n | App |
|---------|---------------|-----|-----|-----|
| Local | PostgreSQL 16 + pgvector en Docker (`localhost:15432`) | Python/Docker en `localhost:9000` | n8n local o Cloud | `flutter run` |
| Demo | Supabase (Session pooler 5432) | EC2 Ubuntu + Docker + Caddy | n8n Cloud | APK release |
| Producción | Supabase con backups | EC2 con Auto Scaling / ALB | n8n Cloud o self-hosted | Play Store |

Recomendaciones de infraestructura:

- **EC2**: `t3.small` (2 vCPU, 2 GB) para MCP + Caddy; `t3.micro` basta para la
  demo si no hay concurrencia.
- **Almacenamiento**: 10–20 GB gp3.
- **IP elástica** para que la URL de `sslip.io` no cambie.
- **Docker Compose** con `restart: unless-stopped` y healthcheck cada 30 s.
- **Caddy** renueva el certificado TLS automáticamente.

---

## 10. Decisiones y trade-offs

| Decisión | Alternativa descartada | Motivo |
|----------|------------------------|--------|
| Flutter | Kotlin nativo / React Native | Una base de código, UI consistente y curva rápida |
| MCP remoto | SQL directo desde n8n | Encapsula reglas académicas y permite reutilizar tools |
| n8n | Backend propio (FastAPI) | Orquestación visual, credenciales y cron sin infraestructura extra |
| pgvector en Supabase | Pinecone / Weaviate | Menos servicios, SQL joins con datos académicos |
| Endpoints estructurados | Todo vía LLM | Latencia, costo y estabilidad de los tableros |
| Datos sintéticos | Datos reales | Privacidad y reproducibilidad |
| Memoria en Postgres | Memoria en el cliente | Sobrevive a reinicios y sirve a varios canales |
| Sin streaming | SSE token por token | Menor complejidad; la demo prioriza claridad |

### Limitaciones conocidas

- El login por código **no autentica**; es una simulación académica.
- El pensum es sintético (51 cursos en total, entre 155 y 172 créditos según el
  programa) y no el oficial vigente.
- No hay notificaciones push activas (el nodo FCM está deshabilitado).
- No hay streaming de respuestas; el usuario espera la respuesta completa.
- La app no cachea datos offline.
- n8n Cloud impone límites de ejecución y de tamaño de payload.

---

## 11. Estructura del repositorio

```
unab-chatbot/
├── README.md                  # visión general y arranque rápido
├── docs/
│   ├── 00-plan.md             # estado de entregables
│   ├── 01-arquitectura.md     # este documento
│   ├── 02-despliegue.md       # guía paso a paso
│   ├── 03-guion-video.md      # guion de la demo
│   └── capturas/              # screenshots del informe
├── database/                  # esquema, seed, vistas, RLS, RAG
├── mcp-server/                # FastMCP + Docker + test_client.py
├── n8n/                       # 4 workflows + guía de importación
├── rag/                       # documentos y pipeline de embeddings
└── app/                       # Flutter (Android)
```

---

## 12. Referencias internas

- Base de datos: [`../database/README.md`](../database/README.md)
- Servidor MCP: [`../mcp-server/README.md`](../mcp-server/README.md)
- Workflows n8n: [`../n8n/README.md`](../n8n/README.md)
- Pipeline RAG: [`../rag/README.md`](../rag/README.md)
- App Flutter: [`../app/README.md`](../app/README.md)
- Despliegue: [`02-despliegue.md`](02-despliegue.md)
- Guion del video: [`03-guion-video.md`](03-guion-video.md)
