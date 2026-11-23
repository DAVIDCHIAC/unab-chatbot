# Guion del video — Chatbot de Apoyo Académico UNAB

**Duración objetivo:** 8–10 minutos
**Formato:** grabación de pantalla 1080p (16:9) + voz en off en español
**Público:** docente y compañeros de la asignatura Biing26 (UCC)

El video debe demostrar **el sistema funcionando**, no leer código. La narrativa
va del problema al recorrido completo de un estudiante, y cierra con la
arquitectura y los límites del alcance.

---

## 0. Antes de grabar (checklist técnico)

### 0.1 Infraestructura

- [ ] Los 4 workflows de n8n están **Active**.
- [ ] `GET https://<mcp>/health` responde `{"status":"ok","database":"ok"}`.
- [ ] `POST /webhook/unab/rag` responde con texto (prueba rápida con `curl`).
- [ ] `POST /webhook/unab/academico/resumen` devuelve datos de `10045234`.
- [ ] `POST /webhook/unab/noticias` con `{"texto":"sostenibilidad"}` devuelve 2 noticias.
- [ ] Se ejecutó `database/08_actualizar_demo.sql` **el mismo día**.
- [ ] El APK instalado apunta a la URL real de n8n (`--dart-define`).

### 0.2 Guion y escena

- [ ] Cerrar notificaciones, Slack, WhatsApp y correo.
- [ ] Modo avión desactivado; WiFi estable.
- [ ] Fuente del teléfono al 100 % de batería o conectado.
- [ ] Navegador sin pestañas personales; zoom al 110–125 %.
- [ ] Terminal con `chcp 65001` (Windows) y fuente legible.
- [ ] Guion impreso o en segunda pantalla.
- [ ] Grabar en horizontal si se muestra el teléfono con espejo; si es emulador,
      ventana 1080×1920 escalada.

### 0.3 Orden de ventanas

1. Diapositiva de portada (o README abierto).
2. Supabase → SQL Editor / Table Editor.
3. Terminal → `curl /health` y `test_client.py`.
4. n8n → WF01 abierto.
5. Emulador o teléfono → app.
6. Cierre → diapositiva de conclusiones.

---

## 1. Escena por escena

### Escena 1 · Portada e introducción — `0:00 – 0:35`

**En pantalla:** título del proyecto, nombre, asignatura y una captura del chat.

**Narración:**

> «Hola. Este es el **Chatbot de Apoyo Académico UNAB**, un asistente para
> estudiantes que responde dudas institucionales, muestra el calendario, explica
> el avance académico y publica noticias y convocatorias.
>
> Lo construí con **Flutter**, **n8n**, un servidor **MCP en AWS** y
> **Supabase con pgvector**. En los próximos minutos voy a mostrar el sistema
> funcionando de punta a punta y cómo está armado por dentro.»

**Tip:** no empieces con diapositivas genéricas; muestra la app en los primeros
5 segundos para enganchar.

---

### Escena 2 · El problema y la solución — `0:35 – 1:30`

**En pantalla:** dos columnas.

| Antes | Ahora |
|-------|-------|
| El estudiante busca en PDFs, correos y páginas dispersas | Un solo chat y tres tableros |
| No sabe por qué no puede matricular una materia | El sistema explica el prerrequisito |
| Las noticias llegan por redes sociales | Ingesta RSS automática cada 6 h |

**Narración:**

> «Hoy la información académica está repartida: reglamento en PDF, fechas en
> carteleras, notas en el portal y noticias en redes. El estudiante pierde tiempo
> y comete errores de matrícula.
>
> La solución tiene cuatro capacidades: **RAG** sobre documentos institucionales,
> **calendario** consultable, **historial y avance** con recomendación de
> matrícula, y **noticias** actualizadas.
>
> Todo pasa por n8n, que decide si responde un agente con Gemini o una consulta
> SQL directa. La app nunca ve llaves ni contraseñas.»

---

### Escena 3 · Base de datos en Supabase — `1:30 – 2:15`

**En pantalla:** Supabase → **Table Editor** → esquema `unab`.

Acciones:

1. Muestra `estudiantes` filtrado por `10045234`.
2. Abre `historial_academico` y filtra el mismo código.
3. Muestra `v_estado_estudiante` y `v_prerrequisitos_pendientes`.
4. Abre `documentos_vectoriales` y señala la columna `embedding`.

**Narración:**

> «La base de datos vive en Supabase, en un esquema propio llamado `unab`.
> Tiene 12 programas, 51 cursos, 30 estudiantes y más de 900 registros de
> historial.
>
> El caso que voy a usar es **Jhon García, código 10045234**, de tercer semestre.
> Reprobó Cálculo Integral con 2.4 y por eso Cálculo Multivariado aparece
> bloqueado.
>
> Las vistas analíticas hacen los joins pesados una sola vez. Y aquí está
> `documentos_vectoriales`: 27 fragmentos de siete documentos institucionales con
> embeddings de 1536 dimensiones, índice HNSW y solapamiento de 160 caracteres.»

**Tip:** si el Table Editor tarda, usa el SQL Editor con una consulta ya escrita.

---

### Escena 4 · Servidor MCP en AWS — `2:15 – 3:05`

**En pantalla:** terminal.

```bash
curl https://TU_ENDPOINT/health
```

```json
{ "status": "ok", "app": "UNAB Academic MCP", "database": "ok" }
```

Luego:

```bash
python test_client.py --url https://TU_ENDPOINT/mcp --token <TOKEN>
```

Muestra cómo lista las 18 herramientas y algunas respuestas `status: ok`.

**Narración:**

> «El servidor MCP corre en una instancia EC2 con Docker y está detrás de Caddy
> con HTTPS. Expone 18 herramientas: identificación del estudiante, estado,
> historial, cursos pendientes, prerrequisitos, proyección, recomendación de
> matrícula, malla curricular, calendario, noticias y búsqueda de conocimiento.
>
> Aquí está el health check y aquí el cliente de prueba ejecutando las 18
> herramientas contra la base de datos real. Todas responden `ok`.
>
> El MCP es la única pieza que habla con Supabase. n8n solo consume herramientas;
> así las reglas académicas quedan en un solo lugar.»

**Tip:** no muestres el token completo; cúbrelo o usa una variable de entorno.

---

### Escena 5 · Workflows de n8n — `3:05 – 3:55`

**En pantalla:** n8n → WF01 abierto.

Acciones:

1. Recorre el grafo: `Webhook RAG → Normalizar → IF → Agente → Formatear → Responder → Registrar`.
2. Abre el nodo **MCP Client UNAB** y muestra el endpoint y las herramientas.
3. Abre **Gemini Chat Model** y muestra `gemini-3.5-flash-lite`, temperatura 0.2.
4. Abre **Memoria de Conversación** y muestra la tabla Postgres.
5. Cambia a WF03 y señala la rama estructurada del resumen.

**Narración:**

> «n8n es el orquestador. El workflow 1 recibe la pregunta, valida que no esté
> vacía y se la pasa a un agente de Gemini (`gemini-3.5-flash-lite`).
>
> El agente no inventa: tiene un cliente MCP con herramientas reales. Puede
> buscar en el RAG, consultar el calendario, revisar el estado académico o
> recomendar matrícula.
>
> La memoria está en Postgres, así que el contexto sobrevive a reinicios y sirve
> para varios canales.
>
> Los workflows 2 y 3 tienen dos caminos: uno conversacional con agente y otro
> estructurado que consulta las vistas directamente, sin gastar tokens. Ese es
> el que alimenta las pantallas de la app.»

**Tip:** n8n se ve mejor con zoom al 80–90 % y sin el panel de ejecuciones.

---

### Escena 6 · App: login y chat RAG — `3:55 – 5:10`

**En pantalla:** emulador o teléfono.

Acciones:

1. Abre la app → pantalla de login.
2. Pulsa **Probar con el estudiante demo**.
3. En la pestaña **Chat**, pulsa la sugerencia
   **«¿Cuáles son los requisitos de grado?»**.
4. Espera la respuesta (3–12 s). Señala el Markdown, las listas y los enlaces.
5. Pregunta: **«¿Qué pasa si pierdo una materia?»** para mostrar el seguimiento
   con memoria.

**Narración:**

> «Esta es la app Flutter. El login es demostrativo: con un toque entro como el
> estudiante 10045234.
>
> En el chat pregunto por los requisitos de grado. La app envía la pregunta a
> n8n; el agente consulta el RAG por MCP y redacta la respuesta.
>
> La respuesta llega en Markdown, con viñetas y enlaces que se abren en el
> navegador. La latencia ronda los 4 segundos porque incluye la llamada a
> Gemini.
>
> Hago una segunda pregunta relacionada y el agente recuerda el contexto: eso es
> la memoria en Postgres.»

**Tip:** si la respuesta tarda, corta el tiempo muerto en edición con un
fundido; no aceleres el texto.

---

### Escena 7 · Calendario — `5:10 – 6:00`

**En pantalla:** pestaña **Calendario**.

Acciones:

1. Muestra la lista de eventos con fechas y días faltantes.
2. Pulsa el filtro **Exámenes**.
3. Abre el panel de preguntas y usa **«¿Cuándo son los exámenes finales?»**.
4. Vuelve a **Todos** y muestra la variedad de categorías.

**Narración:**

> «La pestaña de calendario no usa el modelo de lenguaje para listar: llama a un
> endpoint estructurado que consulta la vista de próximos eventos. Por eso carga
> en menos de un segundo.
>
> Puedo filtrar por matrícula, exámenes, clases, pagos o ceremonia. Y si quiero
> preguntar en lenguaje natural, uso el asistente: el agente consulta la misma
> información y responde con fechas y días restantes.
>
> Las fechas son relativas a hoy porque el script de demo las regenera antes de
> grabar.»

---

### Escena 8 · Historial y avance (caso estrella) — `6:00 – 7:20`

**En pantalla:** pestaña **Académico**.

Acciones:

1. Muestra el encabezado: nombre, semestre, promedio y barra de avance.
2. Señala las **alertas**.
3. Baja a **cursos bloqueados**: `IS301` por `IS201` reprobado.
4. Muestra el historial reciente.
5. En el panel, pulsa **«¿Qué puedo matricular el próximo semestre?»**.
6. Deja que la respuesta explique el bloqueo y proponga alternativas.

**Narración:**

> «Esta es la pantalla más importante. Arriba, el resumen: tercer semestre,
> promedio 3.69 y 18.8 % de avance.
>
> El sistema detecta una alerta: tiene un curso reprobado. Y aquí está la
> consecuencia: Cálculo Multivariado está bloqueado porque Cálculo Integral, su
> prerrequisito, no se aprobó.
>
> Le pregunto qué puede matricular. El agente usa las herramientas del MCP:
> consulta historial, prerrequisitos, créditos y proyección, y recomienda un plan
> que sí respeta las reglas. Esto es lo que un estudiante no puede deducir
> fácilmente de un PDF.»

**Tip:** esta escena es el clímax; dale tiempo a la respuesta y no la cortes.

---

### Escena 9 · Noticias y convocatorias — `7:20 – 8:00`

**En pantalla:** pestaña **Noticias**.

Acciones:

1. Muestra la lista con fuente y fecha.
2. Pulsa el filtro **Becas**.
3. Abre una noticia: se abre el navegador con la URL.
4. Vuelve y filtra **Convocatorias**.

**Narración:**

> «Las noticias se alimentan por un flujo programado: cada seis horas n8n lee dos
> fuentes RSS, filtra por fecha y tema, normaliza los ítems y los guarda en
> Supabase con *upsert*.
>
> La app consulta la vista de noticias recientes y permite filtrar por becas,
> convocatorias, eventos o cursos. Cada tarjeta abre la fuente original.
>
> El nodo de notificaciones push está implementado pero deshabilitado: activarlo
> solo requiere la clave de Firebase.»

---

### Escena 10 · Arquitectura, seguridad y cierre — `8:00 – 9:10`

**En pantalla:** diagrama de arquitectura de `docs/01-arquitectura.md`.

Recorre con el cursor:

1. App → n8n → MCP → Supabase.
2. Gemini para LLM y embeddings.
3. Caddy/EC2.
4. La nota de «sin secretos en la app».

**Narración:**

> «Resumiendo la arquitectura: la app solo habla con n8n por HTTPS. n8n
> orquesta agentes y consultas. El MCP encapsula el acceso a datos y las reglas
> académicas. Supabase guarda todo, incluidos los vectores. Gemini aporta el
> modelo y los embeddings.
>
> En seguridad: el MCP exige Bearer token y valida el host para evitar DNS
> rebinding; la base tiene RLS para clientes; la app no contiene secretos.
>
> Limitaciones honestas: el login no autentica, los datos son sintéticos, no hay
> streaming ni caché offline, y los webhooks están públicos para facilitar la
> demo. En producción se activa Header Auth y Supabase Auth.
>
> El repositorio incluye la base de datos, el servidor MCP, los cuatro workflows,
> el pipeline RAG, la app Flutter y la guía de despliegue paso a paso. Gracias.»

---

### Escena 11 · Cierre — `9:10 – 9:30`

**En pantalla:** logo o título + repositorio + correo.

**Narración:**

> «Todo el código y la documentación están en el repositorio. Si quieren
> reproducirlo, empiecen por `docs/02-despliegue.md`. Gracias por su atención.»

---

## 2. Preguntas de respaldo

Si alguna respuesta falla o tarda demasiado, usa estas preguntas ya probadas:

| Módulo | Pregunta | Qué debe mostrar |
|--------|----------|------------------|
| RAG | ¿Cuáles son los requisitos de grado? | Lista de requisitos y enlaces |
| RAG | ¿Qué becas ofrece la UNAB? | Becas y monitorías |
| RAG | ¿Cómo cancelo una materia? | Procedimiento y fechas |
| Calendario | ¿Cuándo es la matrícula del próximo semestre? | Fechas y días faltantes |
| Calendario | ¿Cuándo son los exámenes finales? | Semana de exámenes |
| Académico | ¿Cuál es mi avance? | Porcentaje y créditos |
| Académico | ¿Qué cursos tengo bloqueados? | `IS301` y el motivo |
| Académico | ¿Qué puedo matricular el próximo semestre? | Plan que respeta prerrequisitos |
| Noticias | (filtro Becas) | Tarjetas con URL |

---

## 3. Plan de grabación (storyboard)

| # | Escena | Duración | Fuente | Transición |
|---|--------|----------|--------|------------|
| 1 | Portada | 0:35 | Diapositiva | Fundido |
| 2 | Problema/solución | 0:55 | Diapositiva | Corte |
| 3 | Supabase | 0:45 | Navegador | Zoom suave |
| 4 | MCP en EC2 | 0:50 | Terminal | Corte |
| 5 | n8n | 0:50 | Navegador | Corte |
| 6 | Login + chat RAG | 1:15 | Emulador | Corte |
| 7 | Calendario | 0:50 | Emulador | Corte |
| 8 | Académico | 1:20 | Emulador | Corte |
| 9 | Noticias | 0:40 | Emulador | Corte |
| 10 | Arquitectura y cierre | 1:10 | Diapositiva | Fundido |
| 11 | Cierre | 0:20 | Diapositiva | Fundido a negro |

**Total:** ~9:30

---

## 4. Producción

### 4.1 Grabación

- **Herramientas:** OBS Studio (pantalla + micrófono), Loom o QuickTime.
- **Resolución:** 1920×1080, 30 fps.
- **Micrófono:** audífono con cable o micrófono USB; evita el altavoz.
- **Audio:** −12 dB de pico, sin clipping; graba una prueba de 10 s.
- **Teléfono:** usa `scrcpy` o el espejo de Android Studio para verlo en el PC.
- **Cursor:** agrandado y con clics resaltados (opción de OBS o Windows).

### 4.2 Edición

- **Cortes:** elimina silencios mayores a 1.5 s y tiempos de espera del LLM.
- **Censura:** cubre tokens, correos y contraseñas con un rectángulo.
- **Rótulos:** añade el nombre de cada módulo en la esquina inferior.
- **Zoom:** 105–115 % en las zonas clave (bloqueos, avance, filtros).
- **Música:** opcional, volumen −25 dB; no compite con la voz.
- **Subtítulos:** español, incrustados o archivo `.srt`.

### 4.3 Exportación

- MP4 H.264, 1080p, 8–10 Mbps.
- Nombre: `unab-chatbot-demo.mp4`.
- Súbelo a YouTube (no listado) o Drive y pega el enlace en el README.

---

## 5. Checklist posterior

- [ ] El video dura entre 8 y 10 minutos.
- [ ] Se ven las cuatro pestañas de la app.
- [ ] Se ve el caso estrella (`IS301` bloqueado por `IS201`).
- [ ] Se ve el `/health` del MCP y las 18 herramientas.
- [ ] Se ve al menos un workflow de n8n.
- [ ] No hay tokens, correos ni contraseñas visibles.
- [ ] El audio es claro y constante.
- [ ] Los acentos y nombres se pronuncian correctamente.
- [ ] El enlace está en el README (`## 9. Video de demostración`).
- [ ] Las capturas de `docs/capturas/` coinciden con lo mostrado.

---

## 6. Errores frecuentes al grabar

| Problema | Solución |
|----------|----------|
| La app muestra aviso amarillo de URL | Recompilar con `--dart-define` real |
| El calendario está vacío | Ejecutar `08_actualizar_demo.sql` |
| El chat tarda más de 30 s | Revisar `/health` del MCP y los logs de n8n |
| n8n responde 404 | Activar el workflow y usar la Production URL |
| Se ve el token del MCP | Regrabar la escena o censurar en edición |
| El teléfono se ve borroso | Usar `scrcpy` con bitrate alto o emulador 1080p |
| La voz suena metálica | Grabar en una habitación con textiles y micrófono cercano |
