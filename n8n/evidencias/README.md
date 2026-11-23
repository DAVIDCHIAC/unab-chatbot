# Evidencia de ejecución de webhooks

Fecha: 2026-11-23 19:13:08 UTC. Base: `https://unab-chatbot.app.n8n.cloud`.

| Workflow | Ruta | HTTP | Resultado |
|---|---|---:|---|
| WF01 RAG | `/webhook/unab/rag` | 200 | rag · ok=True · Para obtener el título de pregrado en la UNAB, debes cumplir con los s |
| WF02 Calendario chat | `/webhook/unab/calendario` | 200 | calendario · ok=True · Para el periodo académico activo (Segundo semestre 2026, del 15/07/202 |
| WF03 Académico chat | `/webhook/unab/academico` | 200 | academico · ok=True · **a) Resumen del estado académico:** Estás matriculado en el **3er sem |
| WF02 Calendario lista | `/webhook/unab/calendario/lista` | 200 |  · ok=True ·  |
| WF03 Resumen académico | `/webhook/unab/academico/resumen` | 200 |  · ok=True ·  |
| WF04 Noticias | `/webhook/unab/noticias` | 200 |  · ok=True ·  |

Las respuestas completas están en `respuestas_webhooks.json`.
