# Configuración manual de n8n (plan Free Trial, sin API pública)

> **Estado final (22/11): completado.** Los 4 workflows están publicados y los
> 6 webhooks responden HTTP 200. Esta guía queda como referencia de cómo se
> crearon las credenciales y de los ajustes que fueron necesarios.

El plan de prueba de n8n Cloud no expone `Settings → n8n API`, así que las
credenciales se crearon con el ratón. La API MCP de n8n sí permite leer y
modificar workflows, y de ahí se replicaron las referencias al resto de nodos.

---

## 1. Instancia

<https://unab-chatbot.app.n8n.cloud>

| Workflow | ID |
|----------|----|
| WF01 · Asistente RAG institucional | `xN04k0VZw4EPnUt5` |
| WF02 · Calendario académico | `ijxRYePqtaykOzU8` |
| WF03 · Historial y avance académico | `6RAjFQ9pPT7DCfqv` |
| WF04 · Noticias | `6dEM7t1ptkjdjNPB` |

---

## 2. Credenciales creadas

| Nombre en n8n | Tipo | ID | Uso |
|---------------|------|----|-----|
| `Postgres account` | `postgres` | `39iAaWBFxHtb71mo` | Memoria del chat, SQL de calendario/resumen/noticias |
| `Bearer Auth account` | `httpBearerAuth` | `eLUbftDxt17kI1Zn` | Nodos `MCP Client` |
| `Google Gemini(PaLM) Api account` | `googlePalmApi` | `7gB4tz09OzQfa3ba` | Los 3 nodos `Gemini Chat Model` |

### 2.1 Postgres (Supabase)

| Campo | Valor |
|-------|-------|
| Host | `aws-1-us-west-2.pooler.supabase.com` |
| Database | `postgres` |
| User | `postgres.cnbdkxxvdiagxukrhdzj` |
| Password | `<password-del-entorno>` (no se versiona; se rota antes de producción) |
| Port | `5432` |
| SSL | **Require** |
| **Ignore SSL Issues (Insecure)** | **ON** (obligatorio: el runner de n8n Cloud no valida la cadena del pooler) |
| **SSH Tunnel** | **OFF** (si está ON, n8n intenta `127.0.0.1:22`) |

### 2.2 Bearer (MCP)

Token: `<MCP_BEARER_TOKEN>` (guardado solo en la credencial de n8n y en el `.env` del servidor MCP)

> Nota importante: el nodo `MCP Client` de esta versión de n8n Cloud **no reenvía
> el header `Authorization`**. El servidor MCP acepta peticiones sin token solo
> cuando llegan por el hostname `*.trycloudflare.com` (nunca por IP directa).
> Ese parche está persistido en `mcp-server/server.py`.

### 2.3 Gemini (LLM)

API Key: `<GEMINI_API_KEY>` (guardada solo en la credencial de n8n)

Modelo configurado en los 3 nodos: **`models/gemini-3.5-flash-lite`**.

- `models/gemini-3.8-flash` → HTTP 429 (cuota agotada en la clave de demo).
- `models/gemini-2.5-flash` → HTTP 404 (ya no disponible para cuentas nuevas).
- El esquema de herramientas MCP se saneó en el servidor (`anyOf`/`type` arrays y
  `default: null`) porque Gemini rechazaba esos valores en los *function calls*.

---

## 3. Nodos cubiertos

| Workflow | Postgres | Bearer | Gemini |
|----------|----------|--------|--------|
| WF01 | `Memoria de Conversación`, `Registrar Conversación` | `MCP Client UNAB` | `Gemini Chat Model` |
| WF02 | `Memoria de Conversación`, `Registrar Conversación`, `Consultar Calendario (SQL)` | `MCP Client Calendario` | `Gemini Chat Model` |
| WF03 | `Memoria de Conversación`, `Registrar Conversación`, `Consultar Resumen (SQL)` | `MCP Client Académico` | `Gemini Chat Model` |
| WF04 | `Guardar Noticias (upsert)`, `Consultar Noticias (SQL)`, `Registrar Consulta Noticias` | — | — |

---

## 4. Endpoint del MCP

`https://delight-bit-twenty-walker.trycloudflare.com/mcp`

Si el túnel cambia tras un reinicio de la EC2:

```powershell
python n8n/actualizar_mcp.py <NUEVA_URL>
python n8n_setup.py publish
```

> **Rotación del 23/11:** tras un reinicio de la EC2, Cloudflare asignó un nuevo
> hostname. El timer `unab-tunel-sync` actualizó `MCP_ALLOWED_HOSTS`, pero el
> contenedor en ejecución conservaba la configuración anterior; fue necesario
> recrearlo (`docker compose up -d --build`) para que aceptara el nuevo `Host`.
> Además se alineó WF03 con `models/gemini-3.5-flash-lite` y se corrigió el
> nombre de las columnas `*_prerequisito` en su consulta de resumen.
>
> **Segunda rotación del 23/11 (19:00 UTC):** el túnel pasó a
> `delight-bit-twenty-walker.trycloudflare.com`. Procedimiento aplicado: recrear
> el contenedor y volver a publicar los 3 workflows con `actualizar_mcp.py`.
> La interfaz web (`index.html`) reintenta automáticamente hasta 3 veces porque
> Gemini responde de forma intermitente con *Failed to parse stream*.

`Enviar Push FCM` (WF04) permanece desactivado a propósito: es un placeholder de
Firebase sin credenciales; el resto del workflow funciona igual.

---

## 5. Publicación y pruebas

```powershell
python n8n_setup.py status     # credenciales asignadas
python n8n_setup.py publish    # activa los 4 workflows
python test_6_v2.py            # dispara los 6 webhooks
```

Resultado de la última pasada (22/11):

| Webhook | Resultado |
|---------|-----------|
| `POST /webhook/unab/rag` | ✅ 200 · respuesta RAG con fuente `proceso_grado.md` |
| `POST /webhook/unab/calendario` | ✅ 200 · exámenes finales 26/11–03/12 |
| `POST /webhook/unab/academico` | ✅ 200 · promedio 3.69, 6 bloqueos, recomendación |
| `POST /webhook/unab/noticias` | ✅ 200 · 10 noticias |
| `POST /webhook/unab/calendario/lista` | ✅ 200 · búsqueda `examen` sin tilde devuelve 2 eventos |
| `POST /webhook/unab/academico/resumen` | ✅ 200 · estado + avance + proyección + alertas |

Payload de los agentes: **`{"pregunta":"...","session_id":"...","id_estudiante":"10045234"}`**.
El campo `mensaje` no funciona y produce respuestas vacías.

---

## 6. Valores de referencia (demo)

```
Supabase  postgresql://postgres.<PROYECTO>:<PASSWORD>
          @aws-1-us-west-2.pooler.supabase.com:5432/postgres?sslmode=require
MCP       https://<tunnel>.trycloudflare.com/mcp
Token     <MCP_BEARER_TOKEN>
Gemini    <GEMINI_API_KEY>
```

> Son credenciales de **demostración académica**. Antes de publicar el proyecto
> hay que rotar la contraseña de Supabase, el token del MCP y la clave de
> Gemini, y moverlas a variables de entorno (ver `docs/02-despliegue.md` §9).
