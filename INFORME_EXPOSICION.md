# Informe de exposición · Chatbot de Apoyo Académico UNAB

**Asignatura:** Biing26 · Universidad Cooperativa de Colombia (UCC)  
**Proyecto:** Chatbot de Apoyo Académico UNAB  
**Repositorio:** <https://github.com/DAVIDCHIAC/unab-chatbot>  
**Duración sugerida:** 3 a 5 minutos

> Versión resumida para exponer en clase. La documentación completa está en
> [`README.md`](README.md). Los datos son **sintéticos**: no hay información real
> de estudiantes.

---

## Guion rápido para el expositor

| Tiempo | Qué decir |
|--------|-----------|
| 0:00 – 0:30 | El problema y la idea (sección 1) |
| 0:30 – 1:20 | Qué tecnologías se usaron (sección 2) |
| 1:20 – 1:50 | Arquitectura en una frase (sección 3) |
| 1:50 – 2:50 | Los 4 workflows (sección 4) |
| 2:50 – 3:30 | Demo en vivo con 3 preguntas (sección 6) |
| 3:30 – 4:15 | Datos, caso de prueba y evidencias (secciones 5 y 7) |
| 4:15 – 5:00 | Resultados, dificultades y cierre (secciones 8 y 9) |

Si el tiempo aprieta, **no omitas la demo**: es la parte que mejor demuestra el trabajo.

---

## 1. El problema y la idea

Un estudiante suele tener la información académica repartida en varios lugares:
reglamento de grado, calendario de exámenes, historial de notas, prerrequisitos
y noticias de la universidad. Preguntar cada cosa implica revisar documentos o
pantallas distintas.

La solución fue un **asistente conversacional en español** que responde esas
preguntas en un solo lugar. Tiene cuatro capacidades:

1. Responder preguntas institucionales con **RAG** (documentos de la UNAB).
2. Consultar el **calendario académico** en lenguaje natural.
3. Explicar el **avance del estudiante**, sus bloqueos y qué puede matricular.
4. Mostrar **noticias** de educación, tecnología e ingeniería de sistemas.

Todo se hizo con datos de prueba y credenciales de demostración.

---

## 2. Qué se utilizó

| Capa | Tecnología | Para qué sirve en el proyecto |
|------|-----------|-------------------------------|
| Datos | **Supabase PostgreSQL 17 + pgvector** | Guardar programas, cursos, noticias, conversaciones y vectores |
| Vectores | **Gemini Embedding (1536 dimensiones)** | Convertir los documentos en vectores para el RAG |
| Herramientas | **FastMCP (Python) en AWS EC2 + Docker** | Exponer 18 herramientas académicas y de búsqueda |
| Exposición segura | **Cloudflare Tunnel (HTTPS)** | Publicar el MCP sin abrir puertos al público |
| Orquestación | **n8n Cloud** | 4 workflows con agentes, memoria y respuestas HTTP |
| Inteligencia | **Gemini 3.5 Flash Lite** | Redactar las respuestas del chat |
| Cliente | **Flutter (Android)** | App con login demo, chat, calendario, avance y noticias |
| Scraper | **RSS + cron cada 6 horas** | Traer noticias de 2 fuentes y filtrarlas |
| Memoria | **Tabla Postgres de n8n** | Recordar la conversación por `session_id` |

**Punto clave:** la app no guarda contraseñas ni llaves. Solo conoce la URL de
n8n; las credenciales viven en los servicios desplegados.

---

## 3. Arquitectura en una frase

> La app Flutter habla con **n8n Cloud**; n8n usa **Gemini** para razonar y
> llama al **MCP en la EC2**, que consulta **Supabase/pgvector** y devuelve los
> datos. El resultado vuelve a la app como JSON.

```
App Flutter  --->  n8n Cloud  --->  Gemini
                       |             |
                       +--->  MCP (EC2)  --->  Supabase + pgvector
                       |
                       +--->  Scraper RSS (WF04)
```

---

## 4. Los 4 workflows

| Workflow | Endpoint principal | Qué hace |
|----------|-------------------|----------|
| **WF01 · RAG institucional** | `POST /webhook/unab/rag` | Busca en 7 documentos y responde con fuente |
| **WF02 · Calendario** | `POST /webhook/unab/calendario` | Consulta fechas y eventos académicos |
| **WF03 · Académico** | `POST /webhook/unab/academico` | Usa herramientas MCP para ver notas, créditos y bloqueos |
| **WF04 · Noticias** | `POST /webhook/unab/noticias` | Consulta noticias guardadas por el scraper |

Además de los 4 agentes hay **3 endpoints estructurados sin LLM**, que alimentan
las pantallas de la app y son más rápidos:

- `POST /webhook/unab/calendario/lista`
- `POST /webhook/unab/academico/resumen`
- `POST /webhook/unab/noticias`

Cada agente usa el mismo cuerpo de petición:

```json
{
  "session_id": "demo-001",
  "pregunta": "¿Cuál es mi promedio?",
  "id_estudiante": "10045234"
}
```

---

## 5. Datos de demostración

| Dato | Cantidad |
|------|----------|
| Programas académicos | 12 |
| Cursos | 51 |
| Prerrequisitos | 37 |
| Estudiantes | 30 |
| Registros de historial | 908 |
| Eventos de calendario | 26 |
| Noticias | 20 |
| Documentos del RAG | 7 |
| Fragmentos con embedding | 27 |
| Vistas SQL | 11 |

**Caso estrella:** estudiante `10045234`, Jhon García, Ingeniería de Sistemas.
Promedio **3.69**, avance **18.8 %**. Tiene **Cálculo Integral (IS201)**
reprobada con nota **2.4**, por eso **Cálculo Multivariado (IS301)** está
bloqueado y aparece una recomendación de matrícula.

---

## 6. Demo en vivo (para hacer durante la exposición)

Abre el chat de la app o la ventana web de prueba y haz estas tres preguntas:

| Orden | Asistente | Pregunta | Qué debe responder |
|-------|-----------|----------|--------------------|
| 1 | Asistente UNAB | *¿Cuáles son los requisitos de grado?* | 6 requisitos y la fuente `proceso_grado.md` |
| 2 | Calendario | *¿Cuándo son los exámenes finales?* | 26/11/2026 al 03/12/2026 |
| 3 | Mi avance | *¿Cuál es mi promedio y cuántos créditos me faltan?* | Promedio 3.69, 130 créditos, 6 bloqueos |

**Frase para el cierre de la demo:** “La respuesta no viene de un texto fijo:
el agente elige una herramienta MCP, consulta la base de datos y Gemini redacta
la respuesta en lenguaje natural”.

---

## 7. Evidencias (enlaces para mostrar si preguntan)

- [README completo](README.md) — documento principal.
- [Respuestas de los 6 webhooks](n8n/evidencias/respuestas_webhooks.json) — **6/6 HTTP 200**.
- [Recuperación RAG](rag/evidencias/recuperacion_ejemplo.json) — pregunta y 5 fragmentos con scores.
- [Ejecución del scraper](n8n/evidencias/ejecucion_scraper.json) — 9 + 27 ítems RSS → noticias guardadas.
- [Verificación de Supabase](database/evidencias/verificacion_supabase.txt) — conteos y consulta vectorial.
- [Respuesta académica persistida](database/evidencias/respuesta_personalizada.json).
- [Capturas](docs/capturas/README.md) — 7 imágenes del sistema.
- [APK release](app/build/app/outputs/apk/release/app-release.apk) — instalable (~50 MB).

---

## 8. Resultados y dificultades superadas

**Resultados**

- Los **6 webhooks responden 200** con datos reales del entorno desplegado.
- El RAG recuperó 27 fragmentos homogéneos del mismo modelo de embeddings.
- El scraper procesó dos fuentes RSS y aplicó filtros de **45 días** y de tema.
- El MCP expone 18 herramientas y pasó la prueba de salud en producción.

**Dificultades que se resolvieron**

- El túnel de Cloudflare cambió de URL al reiniciarse la EC2; se actualizó n8n y
  se recreó el contenedor para aceptar el nuevo hostname.
- Se corrigió un error de nombres de columnas (`prerequisito`) en WF03.
- Se alineó WF03 con el modelo Gemini vigente (`gemini-3.5-flash-lite`).

Esto quedó documentado en
[`n8n/CONFIGURACION_MANUAL.md`](n8n/CONFIGURACION_MANUAL.md).

---

## 9. Cierre

El proyecto cumple los componentes pedidos: base de datos con búsqueda
vectorial, servidor MCP, 4 workflows con agente/LLM/memoria, app Android,
scraper y webhooks probados. La demostración se hace **en vivo**; el video queda
como material pendiente.

**Aportación pedagógica:** el sistema no reemplaza al docente: automatiza
consultas repetitivas, explica prerrequisitos con datos y deja una recomendación
clara para que el estudiante tome decisiones con el acompañamiento académico.

---

## 10. Preguntas que podrían hacerte

| Pregunta | Respuesta corta |
|----------|-----------------|
| ¿Los datos son reales? | No. Son 100 % sintéticos, generados para la demostración. |
| ¿Por qué MCP y no SQL directo en n8n? | El MCP encapsula las reglas académicas y expone herramientas reutilizables. |
| ¿Por qué Supabase? | Es PostgreSQL administrado y soporta pgvector sin infraestructura extra. |
| ¿Qué pasa si Gemini falla? | El RAG tiene fallback textual y los tableros funcionan sin LLM. |
| ¿La app guarda contraseñas? | No. Solo conoce la URL pública de n8n. |
| ¿Se puede instalar? | Sí, el APK release está en el repositorio. |
| ¿Cómo se prueba el chat? | Escribiendo en la app o en la ventana web; cada pregunta usa un `session_id`. |
