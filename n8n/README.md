# Módulo 3 · Workflows de n8n

Cuatro flujos que conectan la app Flutter con el servidor MCP y con Supabase.
Los archivos de esta carpeta se importan directamente en **n8n Cloud**
(*Workflows → Import from File*).

| Archivo | Workflow | Disparador | Núcleo |
|---------|----------|------------|--------|
| `wf01_rag_institucional.json` | Asistente RAG institucional | `POST /webhook/unab/rag` | AI Agent + MCP (RAG, calendario, noticias, académico) |
| `wf02_calendario.json` | Calendario académico | `POST /webhook/unab/calendario` y `POST /webhook/unab/calendario/lista` | AI Agent + MCP + consulta SQL de la vista |
| `wf03_historial_mcp.json` | Historial y avance | `POST /webhook/unab/academico` y `POST /webhook/unab/academico/resumen` | AI Agent + 11 herramientas académicas del MCP + resumen SQL |
| `wf04_noticias.json` | Noticias y convocatorias | Cron cada 6 h + `POST /webhook/unab/noticias` | RSS → Supabase (upsert) y consulta SQL de la vista |

> Los tres primeros workflows usan **memoria de conversación** en Postgres
> (`unab_chat_memory`, la crea n8n automáticamente en el esquema `public`).
>
> WF02, WF03 y WF04 exponen además **endpoints estructurados** que alimentan
> las pantallas de la app (listado de calendario, resumen académico y noticias)
> sin pasar por el LLM. Responden más rápido y con datos listos para pintar.

> **¿Estás en el plan Free Trial?** Ese plan no expone la API pública de n8n, así
> que las credenciales se crean a mano. Sigue
> [`CONFIGURACION_MANUAL.md`](CONFIGURACION_MANUAL.md): son **2 credenciales y
> 1 selección de modelo**, y el resto (asignar a 22 nodos, publicar y probar los
> 6 webhooks) lo automatiza el servidor MCP.

---

## 1. Requisitos previos

1. Una instancia de **n8n Cloud** con los nodos de LangChain habilitados
   (vienen por defecto).
2. El **servidor MCP desplegado** y accesible por HTTPS.
   Ver [`../mcp-server/README.md`](../mcp-server/README.md).
3. La **base de datos de Supabase** con los scripts `01` a `08` ejecutados.
   Ver [`../database/README.md`](../database/README.md).
4. Una credencial **Google Gemini(PaLM) API** con tu clave personal. Está
   asignada a los 3 nodos `Gemini Chat Model` (WF01–WF03).

### Variables que debes revisar tras importar

| Qué | Dónde | Valor de ejemplo |
|-----|-------|------------------|
| URL del MCP | Nodos `MCP Client *` → *Endpoint* | `https://TU_TUNEL.trycloudflare.com/mcp` |
| Token del MCP | Credencial `UNAB MCP Bearer` | el valor de `MCP_API_TOKEN` |
| Modelo LLM | Nodos `Gemini Chat Model` | `models/gemini-3.5-flash-lite` | `gemini-3.5-flash-lite` (puedes cambiarlo a `gemini-3.5-flash`) |
| URL del RSS | Nodo `Leer RSS Google News` | `https://news.google.com/rss/search?q=UNAB+Bucaramanga&hl=es-419&gl=CO&ceid=CO:es-419` |

### Cambiar la URL del MCP

El endpoint del MCP cambia si reinicias el túnel de Cloudflare. Para no editar
tres nodos a mano, usa el script incluido:

```bash
python actualizar_mcp.py --ver                                        # ver la actual
python actualizar_mcp.py https://mi-tunel.trycloudflare.com/mcp       # cambiarla
```

Luego reimporta los workflows o cambia el campo *Endpoint URL* en la interfaz.

---

## 2. Importar los workflows

1. En n8n Cloud entra a **Workflows → Create Workflow → ⋯ → Import from File**.
2. Selecciona cada archivo `.json` de esta carpeta (uno por workflow).
3. Guarda con `Ctrl/Cmd + S`.

Al importar verás tres credenciales marcadas como **“Credential not found”**.
Es normal: los archivos traen referencias de ejemplo. Crea las credenciales
reales y asígnalas en cada nodo (ver sección 3).

---

## 3. Crear las credenciales

### 3.1 LLM (`googlePalmApi`)

1. **Credentials → Add credential → Google Gemini(PaLM) API**.
2. Pega tu API key de Google AI Studio.
3. Nómbrala `UNAB Gemini`.
4. Asígnala en los nodos **Gemini Chat Model** de WF01, WF02 y WF03.
5. Modelo: `models/gemini-3.5-flash-lite`, temperatura `0.2`.

En la instancia desplegada se usa `gemini-3.5-flash-lite`: `3.8-flash` agotó la
cuota de la clave demo y `2.5-flash` ya no está disponible para cuentas nuevas.

### 3.2 Postgres de Supabase (`postgres`)

1. En Supabase: **Project Settings → Database → Connection string → URI**.
2. Usa la conexión **Session pooler** (puerto `5432`) o la **directa**.
   Evita el *transaction pooler* (`6543`) con el nodo de memoria.
3. En n8n: **Credentials → Add credential → Postgres**.

| Campo | Valor |
|-------|-------|
| Host | `aws-1-us-west-2.pooler.supabase.com` (el de tu proyecto) |
| Database | `postgres` |
| User | `postgres.<project-ref>` |
| Password | la contraseña de la base de datos |
| Port | `5432` |
| SSL | `require` |

4. Nómbrala `UNAB Supabase Postgres`.
5. Asígnala en:
   - `Registrar Conversación` / `Registrar Consulta Noticias`
   - `Memoria de Conversación`
   - `Guardar Noticias (upsert)`
   - `Consultar Noticias (SQL)`

> Si tu proyecto exige el certificado, usa `verify-full` y pega el CA de
> Supabase en el campo correspondiente.

### 3.3 Bearer del MCP (`httpBearerAuth`)

1. **Credentials → Add credential → Header Auth** y elige el tipo
   **Bearer Auth** (`httpBearerAuth`).
2. Nombre: `UNAB MCP Bearer`.
3. Token: el mismo valor de `MCP_API_TOKEN` del servidor MCP.
4. Asígnala en los nodos `MCP Client UNAB`, `MCP Client Calendario` y
   `MCP Client Académico`.

> Si el servidor MCP se desplegó **sin** `MCP_API_TOKEN`, cambia en cada nodo
> MCP *Authentication* a **None** y borra la credencial.

---

## 4. Endpoints y payloads

Las URLs de producción tienen la forma:

```
https://<tu-instancia>.app.n8n.cloud/webhook/<ruta>
```

Las URLs de prueba (cuando abres el workflow y pulsas *Test workflow*) usan
`/webhook-test/<ruta>` y solo funcionan una vez.

### 4.1 WF01 · `POST /webhook/unab/rag`

```json
{
  "session_id": "ses-001",
  "pregunta": "¿Cuáles son los requisitos de grado?",
  "id_estudiante": "10045234",
  "canal": "android"
}
```

`id_estudiante` es opcional; si se envía, el agente puede consultar datos
académicos. `canal` es opcional (`android`, `web`, `n8n`).

### 4.2 WF02 · `POST /webhook/unab/calendario`

```json
{
  "session_id": "ses-002",
  "pregunta": "¿Cuándo son los exámenes finales?",
  "canal": "android"
}
```

**Listado estructurado** · `POST /webhook/unab/calendario/lista`

```json
{
  "texto": "examen",
  "categoria": "examenes"
}
```

Ambos filtros son opcionales. `texto` busca en `evento` y `descripcion`;
`categoria` debe coincidir con `unab.calendario_academico.categoria`
(`matricula`, `examenes`, `clases`, `pagos`, `ceremonia`, `general`).
Devuelve hasta 60 eventos futuros de `unab.v_calendario_proximo`:

```json
{
  "ok": true,
  "total": 3,
  "eventos": [
    {
      "id": 12,
      "periodo": "2026-20",
      "evento": "Exámenes finales",
      "categoria": "examenes",
      "fecha_inicio": "2026-11-24",
      "fecha_fin": "2026-11-28",
      "descripcion": "Semana de exámenes finales",
      "dias_faltantes": 9
    }
  ]
}
```

### 4.3 WF03 · `POST /webhook/unab/academico`

```json
{
  "session_id": "ses-003",
  "id_estudiante": "10045234",
  "pregunta": "¿Cuál es mi avance y qué puedo matricular?",
  "canal": "android"
}
```

`id_estudiante` es **obligatorio**. Si falta, el workflow responde con un
mensaje pidiendo el código (sin consumir tokens del LLM).

**Resumen estructurado** · `POST /webhook/unab/academico/resumen`

```json
{ "id_estudiante": "10045234" }
```

Devuelve el estado, avance, proyección, alertas, cursos bloqueados e historial
en una sola consulta SQL:

```json
{
  "ok": true,
  "estado": { "nombre_completo": "Jhon García", "semestre_actual": 3 },
  "avance": { "porcentaje_avance": 18.8, "creditos_aprobados": 30 },
  "proyeccion": { "semestres_restantes_estimados": 7 },
  "alertas": [
    { "cursos_reprobados": 1, "cursos_bloqueados": 6, "alertas": ["Tiene asignaturas reprobadas", "Tiene cursos bloqueados por prerrequisito"] }
  ],
  "bloqueados": [
    {
      "curso_bloqueado": "IS301",
      "nombre_curso": "Cálculo Multivariado",
      "codigo_prerequisito": "IS201",
      "estado_prerequisito": "reprobado",
      "tipo_bloqueo": "prerrequisito_reprobado",
      "nota_prerequisito": 2.4
    }
  ],
  "historial": [
    { "codigo_curso": "IS201", "curso": "Cálculo Integral", "periodo": "2026-10", "nota": 2.4, "estado": "reprobado", "intento": 1 }
  ]
}
```

Si el código no existe: `{ "ok": false, "error": "No existe un estudiante con ese código." }`.
Si falta el código: `{ "ok": false, "error": "Debes enviar id_estudiante ..." }`.

### 4.4 WF04 · `POST /webhook/unab/noticias`

```json
{
  "session_id": "ses-004",
  "texto": "becas",
  "categoria": "beca",
  "canal": "android"
}
```

`texto` y `categoria` son opcionales. Categorías válidas:
`convocatoria`, `noticia`, `evento`, `beca`, `curso`.

La respuesta es **estructurada** (la usa la pantalla de Noticias):

```json
{
  "ok": true,
  "total": 2,
  "noticias": [
    {
      "id": 4,
      "titulo": "Beca Excelencia UNAB 2027",
      "resumen": "Dirigida a estudiantes con promedio superior a 4.0",
      "url": "https://www.unab.edu.co/...",
      "fuente": "UNAB",
      "categoria": "beca",
      "fecha_publicacion": "2026-11-10",
      "dias_publicada": 5
    }
  ]
}
```

### 4.5 Respuesta común de los endpoints conversacionales

Aplica a `/unab/rag`, `/unab/calendario` y `/unab/academico`:

```json
{
  "ok": true,
  "session_id": "ses-001",
  "tipo": "rag",
  "respuesta": "Para obtener el título debes ...",
  "latencia_ms": 4210
}
```

Los endpoints estructurados (`/lista`, `/resumen`, `/noticias`) devuelven los
objetos de las secciones 4.2–4.4.

Códigos de error esperados:

| Situación | Respuesta |
|-----------|-----------|
| Pregunta vacía (WF01/WF02) | `ok: true` con un mensaje de ayuda |
| Falta `id_estudiante` (WF03) | `ok: true` pidiendo el código |
| Workflow inactivo | `404` de n8n |
| MCP caído o sin token | `ok: false` / error 500 del nodo |

---

## 5. Probar los workflows

### 5.1 Desde n8n

1. Abre el workflow y pulsa **Test workflow**.
2. En el nodo Webhook elige **Test URL** y envía el JSON de ejemplo.
3. Revisa la salida del agente y del nodo `Registrar Conversación`.

### 5.2 Desde PowerShell

```powershell
$body = @{
  session_id = "ses-001"
  pregunta   = "¿Cuáles son los requisitos de grado?"
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "https://TU-INSTANCIA.app.n8n.cloud/webhook/unab/rag" `
  -ContentType "application/json" `
  -Body $body
```

### 5.3 Desde curl

```bash
curl -X POST "https://TU-INSTANCIA.app.n8n.cloud/webhook/unab/rag" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"ses-001","pregunta":"¿Cuáles son los requisitos de grado?"}'
```

### 5.4 Verificar la base de datos

```sql
SELECT id, session_id, tipo, left(pregunta, 60) AS pregunta,
       left(respuesta, 80) AS respuesta, latencia_ms, created_at
FROM unab.conversaciones
ORDER BY created_at DESC
LIMIT 10;

SELECT id, titulo, categoria, fecha_publicacion
FROM unab.noticias
ORDER BY fecha_scrape DESC
LIMIT 10;
```

---

### 5.5 Probar los endpoints estructurados

```powershell
# Listado de calendario
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

Estos endpoints no llaman al LLM: si fallan, el problema está en la credencial
Postgres o en las vistas, no en el LLM.

---

## 6. Activar en producción

1. Verifica que los 4 workflows tengan las credenciales asignadas.
2. Activa cada workflow con el interruptor **Active**.
3. Copia la **Production URL** de cada nodo Webhook y configúrala en la app
   Flutter con `--dart-define=N8N_BASE_URL=https://<tu-instancia>.app.n8n.cloud`
   (ver [`../app/README.md`](../app/README.md)).
4. Para WF04, el cron se ejecuta cada 6 horas; puedes lanzarlo manualmente con
   **Execute workflow** la primera vez para poblar la tabla.

---

## 7. Mapa de nodos

### WF01 · Asistente RAG institucional

```
Webhook RAG
  └─ Normalizar Entrada
       └─ ¿Pregunta Válida?
            ├─ true  → Agente UNAB ─┐
            └─ false → Respuesta Vacía ─┤
                                        └─ Formatear Respuesta
                                             └─ Responder a la App
                                                  └─ Registrar Conversación
```

Sub-nodos del agente: `Gemini Chat Model`, `MCP Client UNAB`,
`Memoria de Conversación`.

Herramientas MCP expuestas: `buscar_conocimiento_institucional`,
`consultar_calendario`, `obtener_periodo_activo`, `consultar_noticias`,
`identificar_estudiante`, `obtener_estado_academico`, `obtener_historial`,
`obtener_prerrequisitos_pendientes`, `recomendar_matricula`.

### WF02 · Calendario académico

```
Webhook Calendario → Normalizar Entrada → ¿Pregunta Válida?
  ├─ true  → Agente Calendario → Formatear Respuesta → Responder a la App → Registrar Conversación
  └─ false → Respuesta Vacía ─────────────────────────┘

Webhook Calendario Lista → Normalizar Filtro Calendario → Consultar Calendario (SQL)
  → Empaquetar Calendario → Responder Lista Calendario
```

El listado usa `unab.v_calendario_proximo` y responde `{ ok, total, eventos[] }`.
La consulta recibe los filtros como arreglo (`queryReplacement`), no como texto
concatenado, para evitar problemas con comas.

### WF03 · Historial y avance

```
Webhook Académico → Normalizar Entrada → ¿Estudiante Identificado?
  ├─ true  → Agente Académico → Formatear Respuesta → Responder a la App → Registrar Conversación
  └─ false → Respuesta Sin Código ───────────────────┘

Webhook Resumen Académico → Normalizar Resumen → ¿Código para Resumen?
  ├─ true  → Consultar Resumen (SQL) → Empaquetar Resumen → Responder Resumen
  └─ false → Resumen Sin Código ──────────────────────────┘
```

El resumen combina `v_estado_estudiante`, `v_avance_plan`,
`v_proyeccion_semestres`, `v_alertas_academicas`, `v_prerrequisitos_pendientes`
y `v_historial_detalle` en una sola consulta.

### WF04 · Noticias y convocatorias

```
Cada 6 horas → Leer RSS Google News → Normalizar Noticias → Guardar Noticias (upsert)
  → Preparar Notificación → Enviar Push FCM (deshabilitado)

Webhook Noticias → Normalizar Consulta → Consultar Noticias (SQL)
  → Formatear Noticias → Responder Noticias → Registrar Consulta Noticias
```

La rama del webhook responde `{ ok, total, noticias[] }` desde
`unab.v_noticias_recientes`; el cron solo llena la tabla.

---

## 8. Seguridad

- Los webhooks de n8n son **públicos** si no se protegen. Para producción:
  1. En el nodo Webhook, cambia *Authentication* a **Header Auth** y crea una
     credencial `httpHeaderAuth` (por ejemplo header `x-unab-key`).
  2. Envía el mismo header desde la app.
  3. O restringe el acceso con un API Gateway / WAF delante de n8n.
- El servidor MCP ya exige **Bearer token** y valida el header `Host`.
- Nunca subas a Git el archivo `.env`, la API key de Gemini ni la contraseña
  de Supabase. Usa las credenciales de n8n.
- El endpoint académico permite consultar por código de estudiante. En un
  entorno real, valida la identidad con Supabase Auth y no confíes en el
  código que envía el cliente.

---

## 9. Solución de problemas

| Síntoma | Causa probable | Solución |
|---------|----------------|----------|
| `404` al llamar el webhook | Workflow inactivo o URL de prueba | Activa el workflow y usa la Production URL |
| `Credential not found` | Referencias de ejemplo | Crea y asigna las credenciales reales |
| `401 unauthorized` en el MCP | Token ausente o distinto | Revisa la credencial `UNAB MCP Bearer` |
| `ECONNREFUSED` / timeout al MCP | Security Group o Caddy | Abre 443, revisa `MCP_ALLOWED_HOSTS` |
| El agente responde sin datos | No llamó la herramienta | Refuerza el *system message* y baja la temperatura |
| `relation "unab.conversaciones" does not exist` | Scripts SQL no ejecutados | Ejecuta `database/01_schema.sql` … `08` |
| `null value in column "titulo"` en WF04 | El RSS no devolvió ítems | Normal; el workflow termina sin insertar |
| La memoria falla en Supabase | Puerto `6543` (transaction pooler) | Usa el Session pooler (`5432`) |
| Las fechas del calendario están vencidas | Datos de demo antiguos | Ejecuta `database/08_actualizar_demo.sql` |
| `/unab/calendario/lista` responde `eventos: []` | Filtro muy específico o sin eventos futuros | Limpia los filtros y verifica `v_calendario_proximo` |
| `/unab/academico/resumen` responde `ok:false` | Código inexistente o inactivo | Usa un `id_estudiante` de `unab.estudiantes` con estado `activo` |
| `/unab/noticias` responde `total: 0` | Tabla `unab.noticias` vacía | Ejecuta WF04 una vez o `database/08_actualizar_demo.sql` |
| Error `could not determine data type of parameter` | Filtro nulo mal tipado | Mantén los casts `$1::text` / `$2::text` en la consulta |

---

## 10. Cambiar de modelo o de proveedor

El modelo se configura en los nodos **Gemini Chat Model**:

- `models/gemini-3.5-flash-lite`: valor por defecto, con cuota gratuita.
- `models/gemini-3.8-flash`: más capaz, pero agotó la cuota de la clave demo.

Para usar Anthropic, reemplaza el sub-nodo por **Anthropic Chat Model** y
conecta su salida `ai_languageModel` al agente. El resto del workflow no cambia.

Para regenerar los embeddings del RAG:

```bash
cd ../rag
python ingest.py --reindex
```
