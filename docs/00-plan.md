# Plan de trabajo — Chatbot de Apoyo Académico UNAB

Documento vivo. Marca el avance de cada entregable y las decisiones tomadas.

## 1. Mapa de entregables

| # | Entregable | Carpeta / archivo | Estado |
|---|------------|-------------------|--------|
| 1 | Arquitectura del sistema | `docs/01-arquitectura.md` | ✅ **Listo** |
| 2 | Base de datos Supabase | `database/*.sql` | ✅ **Listo (v1)** |
| 3 | Servidor MCP (FastMCP + Docker) | `mcp-server/` | ✅ **Listo (v1, probado en local + Docker)** |
| 4 | Workflows n8n (4 flujos) | `n8n/*.json` | ✅ **Listo (v1, JSON validado)** |
| 5 | App Android (Flutter) | `app/` | ✅ **Código completo + APK compilado** |
| 6 | README profesional + screenshots | `README.md`, `docs/capturas/` | ✅ README listo; 7/7 capturas; video pendiente |
| 7 | Guion del video | `docs/03-guion-video.md` | ✅ **Listo** |

## 2. Estructura del repositorio

```
unab-chatbot/
├── README.md                  # visión general y arranque rápido
├── docs/
│   ├── 00-plan.md             # este archivo
│   ├── 01-arquitectura.md     # diagrama + decisiones
│   ├── 02-despliegue.md       # Supabase, AWS EC2, n8n, Flutter
│   ├── 03-guion-video.md      # guion del video demo
│   └── capturas/              # capturas para el README
│       └── README.md          # convención y guía de captura
├── database/                  # ✅ Módulo 1
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   ├── 03_rag_pgvector.sql
│   ├── 04_vistas.sql
│   ├── 05_rls_policies.sql
│   ├── 06_consultas_demo.sql
│   ├── 07_conocimiento_rag.sql
│   ├── 08_actualizar_demo.sql
│   └── README.md
├── mcp-server/                # ✅ Módulo 2
│   ├── server.py
│   ├── app/
│   │   ├── config.py
│   │   ├── core.py
│   │   ├── db.py
│   │   ├── embeddings.py
│   │   ├── utils.py
│   │   └── tools/
│   ├── test_client.py
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── README.md
│   └── .env.example
├── n8n/                       # ✅ Módulo 3
│   ├── wf01_rag_institucional.json
│   ├── wf02_calendario.json
│   ├── wf03_historial_mcp.json
│   ├── wf04_noticias.json
│   └── README.md
├── rag/                       # ✅ Módulo 4
│   ├── documentos/
│   ├── ingest.py
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
└── app/                       # ✅ Módulo 5
    ├── lib/                   # 30 archivos Dart
    ├── test/                  # 7 pruebas
    ├── android/               # proyecto Android generado
    ├── pubspec.yaml
    ├── analysis_options.yaml
    ├── .gitignore
    └── README.md
```

## 3. Decisiones técnicas ya tomadas

| Tema | Decisión |
|------|----------|
| Esquema de BD | `unab` (separado de `public` y del `ccd` del proyecto de referencia) |
| Embeddings | Gemini `gemini-embedding-001` en producción (Cohere/OpenAI solo como fallback), 1536 dimensiones |
| Vector store | Supabase + `pgvector`, índice **HNSW** (cosine) |
| Tabla vectorial | `unab.documentos_vectoriales` compatible con el nodo nativo de n8n |
| RAG | Híbrido: agente con herramienta de recuperación (retrieve-as-tool) |
| Agentes | n8n AI Agent + servidor MCP remoto (HTTP streamable, puerto 9000) |
| Backend MCP | Python + FastMCP + psycopg2, desplegado con Docker en EC2 |
| Seguridad | RLS en Supabase + service_role para el backend + credenciales en n8n |
| Datos | Sintéticos y deterministas (reproducibles) |
| App móvil | **Flutter** (Android; una sola base de código) |
| Canal app ↔ backend | Webhooks REST de n8n (`/webhook/...`) |

### Validación del Módulo 1

Los 8 scripts se ejecutaron de punta a punta en **PostgreSQL 16 + pgvector**
(contenedor Docker, entorno local) sin errores. La validación de producción se
repitió en **Supabase PostgreSQL 17**; los conteos finales están en
`database/evidencias/verificacion_supabase.txt`:

| Archivo | Resultado |
|---------|-----------|
| `01_schema.sql` | 43 sentencias OK |
| `02_seed.sql` | 12 programas, 51 cursos, 37 prerrequisitos, 30 estudiantes, 908 registros de historial |
| `03_rag_pgvector.sql` | extensión + HNSW + función `buscar_conocimiento` OK |
| `04_vistas.sql` | 11 vistas OK |
| `05_rls_policies.sql` | RLS + 15 políticas OK (con stubs de `auth.uid()`) |
| `06_consultas_demo.sql` | Consultas de verificación OK |
| `07_conocimiento_rag.sql` | 6 documentos y 23 chunks iniciales; tras `ingest.py --reindex` hay 7 documentos y 27 chunks con embedding |
| `08_actualizar_demo.sql` | Periodo, calendario y noticias relativos a `CURRENT_DATE` |

Las consultas de verificación están en `database/06_consultas_demo.sql`.

### Validación del Módulo 2

Probado el 2026-11-11 contra PostgreSQL 16 + pgvector en Docker:

| Prueba | Resultado |
|--------|-----------|
| `server.py` + `/health` | ✅ conexión a BD `ok` |
| `test_client.py` (18 herramientas) | ✅ todas responden `status: ok` |
| Autenticación Bearer | ✅ 401 sin token / acceso con token |
| Protección DNS rebinding | ✅ 421 con `Host` no permitido |
| `docker build` | ✅ imagen construida |
| Contenedor + Postgres en red Docker | ✅ `healthy` y 18 herramientas |
| `docker compose config` | ✅ sintaxis válida |

Desplegado en **EC2 `54.211.28.77`** contra **Supabase** (`cnbdkxxvdiagxukrhdzj`,
us-west-2) y validado desde fuera por el túnel de Cloudflare: 401 sin token,
18 herramientas y 9 llamadas reales con datos del estudiante demo.

### Validación del Módulo 3

Los 4 workflows se generaron y se validaron con un script que comprueba
sintaxis JSON, nombres únicos, destinos de conexión, ramas `true`/`false` de
los nodos IF y referencias `$(...)` a nodos existentes:

| Workflow | Nodos | Validación |
|----------|-------|------------|
| `wf01_rag_institucional.json` | 12 | ✅ JSON y grafo OK |
| `wf02_calendario.json` | 17 | ✅ JSON y grafo OK (incluye rama `/lista`) |
| `wf03_historial_mcp.json` | 19 | ✅ JSON y grafo OK (incluye rama `/resumen`) |
| `wf04_noticias.json` | 13 | ✅ JSON y grafo OK |

Además, los 4 workflows se crearon en la instancia
`https://unab-chatbot.app.n8n.cloud` mediante el servidor MCP de n8n:

| Workflow | ID en n8n | Nodos / conexiones |
|----------|-----------|--------------------|
| WF01 | `xN04k0VZw4EPnUt5` | 12 / 11 |
| WF02 | `ijxRYePqtaykOzU8` | 17 / 15 |
| WF03 | `6RAjFQ9pPT7DCfqv` | 19 / 18 |
| WF04 | `6dEM7t1ptkjdjNPB` | 13 / 10 |

Completado: 3 credenciales asignadas (Postgres, Bearer y Gemini), 4 workflows
publicados y 6/6 webhooks verificados el 22/11. Los agentes usan Gemini
`gemini-3.5-flash-lite` con clave personal de Google AI Studio.

### Validación del Módulo 4 (RAG)

| Prueba | Resultado |
|--------|-----------|
| Documentos con front matter | ✅ 7 archivos, 27 chunks (overlap 160) |
| `ingest.py --reindex --dry-run` | ✅ chunking sin llamadas externas |
| `ingest.py --stats` | ✅ catálogo y conteo de embeddings |
| Embeddings reales de 1536d (Gemini) | ✅ 27/27 chunks, 7 documentos `procesado = TRUE` |
| Búsqueda vectorial en producción | ✅ `modo: "vectorial"`, scores 0.58–0.68 en la pregunta de ejemplo |
| Fallback textual sin API key | ✅ el MCP responde `modo: "texto"` |

### Validación del Módulo 5 (App Flutter)

| Prueba | Resultado |
|--------|-----------|
| Estructura de 30 archivos Dart | ✅ 0 problemas de sintaxis/balance |
| Modelos tolerantes a JSON de Postgres | ✅ `int`, `double` y `String` |
| Contratos de los 6 endpoints | ✅ alineados con los workflows |
| `flutter pub get` (Flutter 3.50.0 / Dart 3.14.0) | ✅ dependencias resueltas |
| `flutter analyze` | ✅ 0 errores (17 avisos info de `material.dart`) |
| `flutter test` | ✅ 7/7 pruebas de modelos y `json_utils` |
| `flutter build apk --release` | ✅ `app-release.apk` de 50.7 MB |

### Validación del Módulo 6 (Documentación)

| Documento | Estado |
|-----------|--------|
| `README.md` raíz | ✅ Arquitectura, arranque, endpoints, capturas |
| `docs/01-arquitectura.md` | ✅ Componentes, flujos, modelo, seguridad |
| `docs/02-despliegue.md` | ✅ Supabase, RAG, EC2, n8n, Flutter |
| `docs/03-guion-video.md` | ✅ 11 escenas, ~9:30 min |
| `docs/capturas/README.md` | ✅ Convención y guía de captura |

## 4. Flujos n8n (implementados)

| WF | Nombre | Trigger | Núcleo |
|----|--------|---------|--------|
| 01 | Asistente RAG institucional | `POST /webhook/unab/rag` | AI Agent + MCP (RAG, calendario, noticias, académico) + memoria Postgres |
| 02 | Calendario académico | `POST /webhook/unab/calendario` y `/calendario/lista` | AI Agent + MCP + consulta SQL de la vista |
| 03 | Historial y avance | `POST /webhook/unab/academico` y `/academico/resumen` | AI Agent + 11 herramientas académicas del MCP + resumen SQL |
| 04 | Noticias y convocatorias | Cron cada 6 h + `POST /webhook/unab/noticias` | RSS → Supabase (upsert) y consulta SQL de `v_noticias_recientes` |

## 5. Accesos que se necesitan

| Servicio | Para qué | ¿Ya lo tienes? |
|----------|----------|----------------|
| Supabase | Ejecutar SQL, credenciales de conexión, Auth | ❓ |
| AWS EC2 (Ubuntu) | Desplegar el contenedor MCP en el puerto 9000 | ❓ |
| n8n Cloud | Importar y probar los 4 workflows | ❓ |
| LLM | Gemini `gemini-3.5-flash-lite` con clave personal | ✅ credencial creada en n8n |
| Embeddings | Gemini (gratis) o Cohere (trial gratis) | ❓ |
| Dominio / túnel | HTTPS para el endpoint MCP | ❓ |
| Firebase (FCM) | Notificaciones push de la app | ❓ |

## 6. Preguntas abiertas

1. ~~**App Android:** ¿Kotlin, Flutter o React Native?~~ → **Flutter**.
2. ~~**Pensum:** ¿sintético u oficial?~~ → sintético (reemplazable sin cambiar columnas).
3. **Auth de la app:** ¿login con correo UNAB (Supabase Auth) o identificación por código?
   → La demo usa código; Supabase Auth queda como trabajo futuro.
4. ~~**Canal:** ¿webhook REST o Supabase directo?~~ → webhooks REST de n8n.
5. ~~**Alcance del video:** ¿cuántos minutos y qué flujos debe mostrar?~~
   → 8–10 min, 11 escenas, los 4 módulos de la app + MCP + n8n.

## 7. Orden sugerido de ejecución

1. ✅ Base de datos (hecho).
2. ✅ Servidor FastMCP + Docker + prueba local (hecho).
3. ✅ Diagrama de arquitectura + README base (hecho).
4. ✅ Despliegue en EC2 + Supabase + prueba externa por túnel (hecho).
5. ✅ Workflows n8n (01 → 02 → 03 → 04) generados y validados.
6. ✅ Pipeline de ingesta RAG y carga de documentos (23 embeddings reales).
7. ✅ App Flutter (código completo, pruebas y APK release compilados).
8. ⏳ Credenciales y publicación ✅; screenshots 1/7 y video pendientes.

## 8. Trabajo pendiente con credenciales reales

| Tarea | Depende de |
|-------|------------|
| Ejecutar los 8 scripts en Supabase | ✅ Ejecutados en Supabase |
| Generar embeddings con `rag/ingest.py --reindex` | ✅ 27 chunks con Gemini |
| Desplegar el MCP en EC2 + Cloudflare Tunnel | ✅ Desplegado y verificado |
| Importar workflows y asignar credenciales | ✅ 4 publicados; 6/6 webhooks OK |
| Compilar APK y probar los 4 módulos | APK ya compilado; falta probarlo contra n8n real |
| Capturar `docs/capturas/01…07.png` | Demo funcionando |
| Grabar y publicar el video | Capturas + guion |
