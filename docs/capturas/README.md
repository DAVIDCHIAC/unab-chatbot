# Capturas para el informe

Esta carpeta guarda las imágenes que acompañan el README y el video. Usa
**exactamente** estos nombres para que los enlaces del repositorio funcionen.

| Archivo | Módulo | Contenido | Dónde se toma |
|---------|--------|-----------|---------------|
| `01-login.png` | App | Pantalla de identificación con el botón **Probar con el estudiante demo** | App Flutter |
| `02-chat.png` | App / WF01 | Chat con una respuesta RAG en Markdown y enlaces | App Flutter |
| `03-calendario.png` | App / WF02 | Listado filtrado por **Exámenes** | App Flutter |
| `04-academico.png` | App / WF03 | Encabezado con avance, alertas y cursos bloqueados | App Flutter |
| `05-noticias.png` | App / WF04 | Noticias filtradas por **Becas** | App Flutter |
| `06-n8n.png` | n8n | Workflow WF01 abierto, con el agente y el MCP Client visibles | n8n Cloud |
| `07-mcp.png` | MCP | Respuesta de `/health` del servidor en EC2 | Navegador o terminal |

---

## 1. Requisitos previos

- Los 4 workflows de n8n **activos**.
- `database/08_actualizar_demo.sql` ejecutado el mismo día.
- APK compilado con la URL real:

  ```bash
  flutter build apk --release \
    --dart-define=N8N_BASE_URL=https://TU-INSTANCIA.app.n8n.cloud
  ```

- Resolución del teléfono/emulador: **1080×1920** (o 1080×2400).
- Tema claro, brillo al 70–80 %, sin modo oscuro.

---

## 2. Cómo capturar

### 2.1 App Flutter

**Opción A — teléfono físico:**

1. Conecta por USB y verifica con `adb devices`.
2. Captura con:

   ```bash
   adb exec-out screencap -p > docs/capturas/01-login.png
   ```

3. Repite cambiando el nombre para cada pantalla.

**Opción B — emulador de Android Studio:**

1. Inicia el emulador y abre la app.
2. Usa el botón de cámara del emulador
   (**Extended Controls → Camera** o el icono de captura).
3. Guarda directamente en `docs/capturas/`.

**Opción C — `scrcpy` (recomendada para video y capturas):**

```bash
scrcpy --screenshot docs/capturas/02-chat.png
```

### 2.2 n8n

1. Abre WF01 en n8n Cloud.
2. Ajusta el zoom al **80–90 %** para que se vea el grafo completo.
3. Cierra el panel de ejecuciones y las notificaciones.
4. Captura la ventana del navegador (`Win + Shift + S` en Windows).
5. Recorta solo el área del workflow; no incluyas la barra de marcadores.

### 2.3 MCP

**Opción A — navegador:**

1. Abre `https://<tu-mcp>/health`.
2. Captura la respuesta JSON con la barra de direcciones visible.

**Opción B — terminal:**

```bash
curl https://organize-removing-levels-auburn.trycloudflare.com/health
```

Captura la terminal con fuente legible y sin el token visible.

---

## 3. Guía por captura

### `01-login.png`

- Pantalla inicial de la app.
- Debe verse el campo de código y el botón **Probar con el estudiante demo**.
- No captures el teclado abierto.

### `02-chat.png`

- Pulsa la sugerencia **«¿Cuáles son los requisitos de grado?»**.
- Espera la respuesta completa.
- Deja visibles la burbuja del usuario, la respuesta con viñetas y al menos un
  enlace.

### `03-calendario.png`

- Entra a **Calendario**.
- Pulsa el filtro **Exámenes**.
- Debe verse al menos un evento con fecha y días faltantes.

### `04-academico.png`

- Entra a **Académico**.
- Captura el encabezado con nombre, semestre, promedio y barra de avance.
- Si cabe, incluye la tarjeta de **cursos bloqueados** con `IS301` / `IS201`.
- Si no cabe en una sola imagen, prioriza el encabezado y usa una segunda
  captura opcional (`04b-academico-bloqueos.png`).

### `05-noticias.png`

- Entra a **Noticias**.
- Pulsa el filtro **Becas**.
- Debe verse al menos una tarjeta con título, resumen y fuente.

### `06-n8n.png`

- Workflow **WF01 · Asistente RAG institucional**.
- Deben distinguirse: `Webhook RAG`, `Agente UNAB`, `Gemini Chat Model`,
  `MCP Client UNAB` y `Responder a la App`.
- No muestres credenciales ni la URL con token.

### `07-mcp.png`

- Respuesta `{"status":"ok","database":"ok"}`.
- Ideal: barra de direcciones con el dominio `trycloudflare.com` y el candado de HTTPS.

---

## 4. Estilo y calidad

| Aspecto | Recomendación |
|---------|---------------|
| Formato | PNG (sin pérdida) |
| Ancho | 1080 px para la app; 1600–1920 px para n8n y navegador |
| Peso | < 500 KB por imagen (optimiza con TinyPNG si hace falta) |
| Bordes | Sin marcos decorativos; recorta el escritorio |
| Texto | Legible al 100 % de zoom en el README |
| Datos | Solo estudiantes sintéticos (`10045234`, etc.) |
| Privacidad | Censura correos personales, tokens, IPs y rutas locales |

---

## 5. Verificación

Antes de hacer commit:

```powershell
Get-ChildItem docs\capturas -Filter *.png |
  Select-Object Name, @{N='KB';E={[math]::Round($_.Length/1KB)}}
```

Deben existir los 7 archivos:

- [x] `01-login.png` — 158 KB, 1344×2992 (emulador `Pixel_8_Pro`)
- [x] `02-chat.png` — 377 KB, 1344×2992 (respuesta RAG con fuente)
- [x] `03-calendario.png` — 313 KB, 1344×2992 (filtro *Exámenes*)
- [x] `04-academico.png` — 288 KB, 1344×2992 (avance y bloqueos)
- [x] `05-noticias.png` — 253 KB, 1344×2992 (filtro *Becas*)
- [x] `06-n8n.png` — 154 KB, 1435×633 (WF01 en n8n Cloud)
- [x] `07-mcp.png` — 9 KB, 685×840 (`/health` en producción)

Y deben verse correctamente en el README raíz:

```markdown
![Login](docs/capturas/01-login.png)
```
---

## 6. Si una captura no coincide

| Captura | Síntoma | Solución |
|---------|---------|----------|
| `02-chat.png` | Respuesta vacía o de error | Revisa `/health` del MCP y los logs de n8n |
| `03-calendario.png` | Lista vacía | Ejecuta `08_actualizar_demo.sql` |
| `04-academico.png` | Sin bloqueos | Verifica el seed de `10045234` (`IS201` reprobado) |
| `05-noticias.png` | Sin tarjetas | Ejecuta WF04 una vez para poblar `unab.noticias` |
| `06-n8n.png` | Grafo cortado | Reduce el zoom o divide en dos capturas |
| `07-mcp.png` | Error 503 | Revisa credenciales de Supabase en el `.env` del MCP |
