# Evidencia de ejecución de webhooks

Fecha: 2026-11-22 21:20:49 UTC · Resultado: **6/6 HTTP 200**.
Base: `https://unab-chatbot.app.n8n.cloud`.

| Workflow | Ruta | Payload de prueba | HTTP | Resultado |
|---|---|---|---:|---|
| WF01 RAG | `/webhook/unab/rag` | `pregunta: ¿Cuáles son los requisitos de grado?` | 200 | 6 requisitos con fuente `proceso_grado.md` · 3937 ms |
| WF02 Calendario chat | `/webhook/unab/calendario` | `pregunta: ¿Cuándo son los exámenes finales?` | 200 | 4 eventos con fechas y días faltantes · 3969 ms |
| WF03 Académico chat | `/webhook/unab/academico` | `id_estudiante: 10045234` | 200 | Resumen, bloqueo `IS301` y recomendación · 2946 ms |
| WF02 Calendario lista | `/webhook/unab/calendario/lista` | `{"texto":"examen"}` | 200 | `total: 2` eventos; búsqueda sin tildes |
| WF03 Resumen académico | `/webhook/unab/academico/resumen` | `{"id_estudiante":"10045234"}` | 200 | Estado, avance 18.8 %, proyección, alertas, 6 bloqueos e historial |
| WF04 Noticias | `/webhook/unab/noticias` | `{"texto":"sostenibilidad"}` | 200 | `total: 2` noticias dentro de la ventana de 45 días |

## Notas

- Los tres primeros webhooks pasan por un **AI Agent** con Gemini
  `gemini-3.5-flash-lite`, herramientas MCP y memoria Postgres.
- Los tres últimos son **endpoints estructurados sin LLM** que consultan vistas
  SQL. No gastan tokens y son los que consumen las pantallas de la app.
- WF02 acepta `examen` sin tilde: el nodo Code normaliza con NFD y la consulta
  usa `translate()`. Antes devolvía HTTP 200 con cuerpo vacío.
- WF04 aplica `CURRENT_DATE - INTERVAL '45 days'`. Con `beca` no hay filas
  porque la beca de excelencia es de enero, fuera de la ventana; por eso la
  prueba usa `sostenibilidad`.
- Las respuestas completas (payload y JSON íntegro) están en
  [`respuestas_webhooks.json`](respuestas_webhooks.json).
- La ejecución real del cron RSS (2 fuentes → 6 noticias insertadas) está en
  [`ejecucion_scraper.json`](ejecucion_scraper.json).
