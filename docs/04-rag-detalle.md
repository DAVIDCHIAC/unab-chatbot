# RAG detallado: chunking, embeddings y recuperación

Este documento complementa el README con las decisiones **técnicas y evaluables**
del pipeline RAG. Toda la evidencia citada está dentro del repositorio.

---

## 1. Pipeline

```
7 documentos Markdown (front matter)
   │  parse_front_matter()
   ▼
párrafos (bloques separados por línea en blanco)
   │  split_long() por oraciones + límite de caracteres
   ▼
chunks con overlap (160 caracteres)
   │  GeminiEmbedding.embed(taskType=RETRIEVAL_DOCUMENT, 1536 dims)
   ▼
unab.documentos_vectoriales (pgvector, índice HNSW coseno)
   │  unab.buscar_conocimiento(query_embedding, 5)
   ▼
agente WF01 / herramienta MCP → respuesta con cita de fuente
```

---

## 2. Parámetros y justificación

| Parámetro | Valor de producción | Justificación |
|-----------|--------------------|---------------|
| `RAG_MAX_CHARS` | 1400 | ~350 tokens por chunk: suficiente para una idea completa y muy por debajo del límite de Gemini (8000 caracteres por entrada). Evita diluir el vector en temas mezclados. |
| `RAG_MIN_CHARS` | 40 | Descarta encabezados sueltos, viñetas vacías y ruido que no aporta al embedding. |
| `RAG_OVERLAP_CHARS` | 160 | ~11 % del chunk. Repite el final del párrafo anterior en el siguiente para que una definición cortada en el borde siga siendo recuperable. El código recorta en espacio en blanco para no partir palabras y nunca excede `MAX_CHARS`. |
| `RAG_BATCH_SIZE` | 64 | Equilibrio entre latencia y cuota; Gemini acepta hasta 100 textos por petición y el script ya subdivide lotes. |
| `EMBEDDING_DIMENSIONS` | 1536 | Coincide con `vector(1536)` y con la salida de `gemini-embedding-001` mediante `outputDimensionality`. |
| Índice | HNSW `vector_cosine_ops` | Mejor *recall* que IVFFlat para colecciones pequeñas y consultas semánticas; no requiere entrenamiento previo. |
| `match_count` | 5 | Suficiente para dar contexto al LLM sin saturar la ventana ni introducir ruido. |

El chunking se hace por **párrafo** porque los documentos institucionales ya
están redactados en unidades semánticas (una regla, un requisito, un
procedimiento). Solo cuando un párrafo supera 1400 caracteres se divide por
final de oración, y el trozo restante se reenvía al siguiente ciclo.

### Ejemplo real de overlap

Salida de `python ingest.py --reindex --dry-run` para
`plan_estudios_ingenieria_sistemas.md`:

- chunk 1 termina en «…comunicación técnica.»
- chunk 2 empieza con «objetivo es que el estudiante pase de la resolución de
  problemas…»

Ese prefijo repetido es el solapamiento de 160 caracteres.

---

## 3. Modelo único de embeddings

La colección de producción usa **un solo modelo** tanto para indexar como para
consultar:

| Uso | Modelo | Parámetros |
|-----|--------|------------|
| Indexación | `gemini-embedding-001` | `taskType=RETRIEVAL_DOCUMENT`, `outputDimensionality=1536` |
| Consulta | `gemini-embedding-001` | `taskType=RETRIEVAL_QUERY`, `outputDimensionality=1536` |
| LLM (n8n) | `gemini-3.5-flash-lite` | temperatura 0.2 |

`ingest.py` escribe en el metadata de cada chunk:

```json
{
  "fuente": "reglamento_estudiantil.md",
  "chunk": 4,
  "modelo": "gemini:gemini-embedding-001",
  "dimensiones": 1536,
  "overlap": 160
}
```

Verificación ejecutada contra la base de datos de producción:

```sql
SELECT metadata->>'modelo' AS modelo,
       metadata->>'dimensiones' AS dims,
       metadata->>'overlap' AS overlap,
       count(*)
FROM unab.documentos_vectoriales
GROUP BY 1, 2, 3;
```

Resultado: **una sola fila** → `gemini:gemini-embedding-001 | 1536 | 160 | 27`.
Es decir, los 27 chunks son homogéneos. El detalle está en
[`rag/evidencias/recuperacion_ejemplo.json`](../rag/evidencias/recuperacion_ejemplo.json).

> El código admite Cohere y OpenAI como *fallback* para reconstruir el índice en
> otro entorno, pero **no se mezclan modelos en una misma reingesta**:
> `--reindex` borra y reinserta todos los chunks de la fuente con el proveedor
> activo. Mezclar vectores de modelos distintos en la misma columna degradaría
> la similitud coseno.

---

## 4. Evidencia de recuperación real

Pregunta enviada: **«¿Qué prerrequisitos bloquean Cálculo Multivariado?»**
Se generó su embedding con `RETRIEVAL_QUERY` y se llamó a
`unab.buscar_conocimiento(..., 5)` sobre el índice HNSW.

| # | Fuente | chunk | Similitud | Fragmento (inicio) |
|---:|--------|------:|----------:|--------------------|
| 1 | `plan_estudios_ingenieria_sistemas.md` | 2 | 0.6759 | «…Cálculo Integral, Álgebra Lineal, Lógica y Programación I…» |
| 2 | `reglamento_estudiantil.md` | 4 | 0.6512 | «La reprobación afecta el promedio y puede bloquear asignaturas…» |
| 3 | `reglamento_estudiantil.md` | 5 | 0.6274 | «Los prerrequisitos son asignaturas que deben estar aprobadas…» |
| 4 | `plan_estudios_ingenieria_sistemas.md` | 3 | 0.6207 | «La reprobación de Cálculo Integral bloquea Cálculo Multivariado…» |
| 5 | `proceso_grado.md` | 1 | 0.5843 | «Para obtener el título de pregrado el estudiante debe aprobar…» |

El agente WF01 recibe estos cinco fragmentos y responde citando
`plan_estudios_ingenieria_sistemas.md`; la respuesta completa de la app está en
[`docs/capturas/02-chat.png`](capturas/02-chat.png) y en
[`n8n/evidencias/respuestas_webhooks.json`](../n8n/evidencias/respuestas_webhooks.json).

---

## 5. Reproducibilidad

```bash
# 1. Ver el chunking sin llamar a APIs
python ingest.py --reindex --dry-run

# 2. Reingestar con el modelo de producción
export EMBEDDING_PROVIDER=gemini
export GEMINI_API_KEY=...
export DATABASE_URL=...
python ingest.py --reindex
python ingest.py --stats

# 3. Verificar en SQL
psql "$DATABASE_URL" -c "SELECT metadata->>'modelo', count(*) FROM unab.documentos_vectoriales GROUP BY 1;"
```

En Windows PowerShell, los `export` se reemplazan por `$env:NOMBRE='valor'`.

---

## 6. Fallback y límites

- Si no hay clave de embeddings, `mcp-server/app/tools/rag.py` cae a búsqueda
  textual (`ILIKE`) y responde `modo: "textual"`. La respuesta sigue siendo
  útil, pero pierde sinonimia.
- Si el embedding de la consulta falla, WF01 devuelve un mensaje de ayuda en
  lugar de un error 500.
- Los documentos son **sintéticos** y están versionados por hash SHA-256: al
  editar un `.md`, `--reindex` actualiza `hash_contenido`, `num_chunks` y
  `updated_at` en `unab.documentos`.
