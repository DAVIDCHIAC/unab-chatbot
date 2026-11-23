# Módulo 4 · Pipeline de ingesta RAG

Convierte los documentos institucionales en **chunks con embeddings** dentro de
Supabase/PostgreSQL, para que el agente de n8n y la herramienta MCP
`buscar_conocimiento_institucional` recuperen contexto real.

```
rag/
├── documentos/                 # fuentes canónicas en Markdown
│   ├── reglamento_estudiantil.md
│   ├── faq_academica.md
│   ├── proceso_grado.md
│   ├── plan_estudios_ingenieria_sistemas.md
│   ├── becas_monitorias.md
│   ├── bienestar_universitario.md
│   └── ccd_competencias_digitales.md
├── ingest.py                   # pipeline con overlap y metadata de modelo
├── requirements.txt
├── .env.example
├── evidencias/
│   └── recuperacion_ejemplo.json  # pregunta → fragmentos con scores
└── README.md
```

---

## 1. Cómo funciona

```
Markdown  →  front matter + párrafos  →  chunks  →  embeddings (Gemini/Cohere/OpenAI)
          →  unab.documentos_vectoriales (pgvector)  →  búsqueda semántica
```

1. **Lectura:** cada `.md` puede tener un front matter sencillo:

   ```markdown
   ---
   titulo: Reglamento Estudiantil UNAB
   categoria: reglamento
   ---
   ```

2. **Chunking:** se divide por párrafos (bloques separados por línea en blanco).
   Los párrafos de más de `RAG_MAX_CHARS` se parten por oraciones. Se descartan
   encabezados y bloques de menos de `RAG_MIN_CHARS` caracteres. Cada chunk
   siguiente recibe los últimos `RAG_OVERLAP_CHARS` caracteres del anterior
   (160 por defecto), recortados en espacio en blanco, para no perder contexto
   en el borde.
3. **Embeddings:** 1536 dimensiones en lotes de 64, con reintentos
   exponenciales. **Producción usa `gemini-embedding-001`** con
   `taskType=RETRIEVAL_DOCUMENT`. El proveedor se elige con `EMBEDDING_PROVIDER`
   (`gemini`, `cohere` u `openai`) o se autodetecta por la clave disponible;
   las alternativas también devuelven 1536 dims, pero no se mezclan en una
   misma reingesta.
4. **Persistencia:** se insertan en `unab.documentos_vectoriales` con metadatos
   (`fuente`, `titulo`, `categoria`, `chunk`, `hash`, `actualizado`, `modelo`,
   `dimensiones`, `overlap`). Así se puede auditar que los 27 chunks salieron
   del mismo modelo.
5. **Catálogo:** se actualiza `unab.documentos` con el hash, el número de chunks
   y `procesado = TRUE`.

> La tabla es **idempotente por fuente**: `--reindex` borra los chunks de ese
> archivo y los vuelve a insertar, sin duplicar.

---

## 2. Requisitos

- Python 3.10 o superior.
- Una API key de **Google Gemini** (gratis en
  <https://aistudio.google.com/apikey>), de **Cohere** (trial gratis en
  <https://dashboard.cohere.com/api-keys>) o de **OpenAI** (de pago).
- La base de datos con los scripts `database/01` … `03` ejecutados
  (extensión `vector`, tablas y función `unab.buscar_conocimiento`).

```bash
cd rag
python -m venv .venv

# Windows
.venv\Scripts\activate
# Linux / macOS
source .venv/bin/activate

pip install -r requirements.txt
```

Copia `.env.example` a `.env` y completa `DATABASE_URL` y **una** de las
claves:

```env
# Opción A — Gemini (gratis, requiere proyecto de Google Cloud activo)
EMBEDDING_PROVIDER=gemini
GEMINI_API_KEY=AIza...

# Opción B — Cohere (trial gratis, sin Google)
# EMBEDDING_PROVIDER=cohere
# COHERE_API_KEY=...

# Opción C — OpenAI (de pago)
# EMBEDDING_PROVIDER=openai
# OPENAI_API_KEY=sk-...
```

Si dejas `EMBEDDING_PROVIDER` vacío, el script autodetecta en este orden:
OpenAI → Gemini → Cohere.

---

## 3. Comandos

| Comando | Qué hace |
|---------|----------|
| `python ingest.py --stats` | Muestra documentos, chunks y cuántos tienen embedding. |
| `python ingest.py --reembed` | Rellena solo los chunks con `embedding IS NULL`. Es el modo por defecto. |
| `python ingest.py --reindex` | Reingesta **todos** los `.md` de `documentos/`. |
| `python ingest.py --file documentos/faq_academica.md` | Reingesta un solo archivo. |
| `python ingest.py --reindex --dry-run` | Muestra el chunking (incluido el overlap) sin llamar a APIs ni a la BD. |
| `python ingest.py --reembed --limit 20` | Procesa como máximo 20 chunks (pruebas). |

### Flujo recomendado

```bash
# 1. Tras ejecutar 07_conocimiento_rag.sql, completa los embeddings
python ingest.py --reembed

# 2. Verifica
python ingest.py --stats

# 3. Cuando edites un documento
python ingest.py --reindex
```

---

## 4. Verificar en Supabase

```sql
-- Estado general
SELECT COUNT(*)                                        AS chunks,
       COUNT(*) FILTER (WHERE embedding IS NOT NULL)   AS con_embedding,
       COUNT(DISTINCT metadata->>'fuente')             AS fuentes
FROM unab.documentos_vectoriales;

-- Documentos procesados
SELECT titulo, fuente, categoria, num_chunks, procesado, updated_at
FROM unab.documentos
ORDER BY updated_at DESC;

-- Prueba de búsqueda semántica (usa el embedding de un chunk existente)
SELECT contenido, metadata->>'fuente' AS fuente, similitud
FROM unab.buscar_conocimiento(
    (SELECT embedding FROM unab.documentos_vectoriales
     WHERE embedding IS NOT NULL LIMIT 1),
    5,
    '{}'::jsonb
);
```

También puedes probar la herramienta MCP directamente:

```bash
python ../mcp-server/test_client.py \
  --url http://127.0.0.1:9000/mcp \
  --token TU_TOKEN
```

---

## 5. Agregar un documento nuevo

1. Crea `rag/documentos/mi_documento.md` con front matter:

   ```markdown
   ---
   titulo: Mi documento
   categoria: institucional
   ---

   # Mi documento

   Primer párrafo...

   Segundo párrafo...
   ```

2. Ejecuta:

   ```bash
   python ingest.py --file documentos/mi_documento.md
   ```

3. El documento queda disponible para el agente sin cambiar código.

Categorías sugeridas: `reglamento`, `faq`, `grado`, `becas`, `bienestar`,
`ccd`, `institucional`.

---

## 6. Costos y rendimiento

- Con **Gemini** (`gemini-embedding-001`) la cuota gratuita de Google AI Studio
  cubre de sobra los 27 chunks actuales y las consultas de la demo.
- Con **Cohere** (clave trial) `embed-v4.0` es gratis hasta 1.000 llamadas al
  mes y 2.000 inputs por minuto: los 27 chunks caben en una sola petición.
- Con **OpenAI**, `text-embedding-3-small` cuesta aproximadamente **USD 0.02 por
  millón de tokens**: los 27 chunks cuestan menos de un centavo.
- `--reembed` solo procesa lo que falta; puedes ejecutarlo varias veces sin
  costo adicional una vez completado.
- Para volúmenes grandes, sube `RAG_BATCH_SIZE` (máximo recomendado: 128) y
  mantén `RAG_MAX_CHARS` entre 1000 y 1800. Gemini acepta como máximo 100
  textos por petición y Cohere 96; el script divide los lotes automáticamente.

---

## 7. Solución de problemas

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `No hay proveedor de embeddings` | No hay `.env` o las claves están vacías | Copia `.env.example` y define `GEMINI_API_KEY`, `COHERE_API_KEY` u `OPENAI_API_KEY` |
| `No se pudo conectar a la base de datos` | Cadena incorrecta o SSL | Usa el Session pooler (`5432`) y `sslmode=require` |
| `relation "unab.documentos_vectoriales" does not exist` | Faltan scripts SQL | Ejecuta `database/01` … `03` |
| `expected 1536 dimensions` | Modelo o dimensiones distintas | Usa `gemini-embedding-001`, `embed-v4.0` o `text-embedding-3-small` con `EMBEDDING_DIMENSIONS=1536` |
| `No se pudieron generar los embeddings` | API key inválida, cuota o red | Revisa la clave, el saldo/cuota y la conexión |
| `400 API key not valid` (Gemini) | Clave mal copiada | Genera otra en <https://aistudio.google.com/apikey> |
| `Failed to create project` (Gemini) | El Workspace bloquea la creación de proyectos | Usa una cuenta Gmail personal o cambia a Cohere |
| `401 invalid api token` (Cohere) | Clave mal copiada o revocada | Genera otra en <https://dashboard.cohere.com/api-keys> |
| `0 chunks` en un archivo | Párrafos muy cortos o solo encabezados | Revisa `RAG_MIN_CHARS` y el contenido |
| Duplicados tras reingestar | Se usó otro nombre de archivo | `--reindex` borra por `metadata->>'fuente'`; mantén el nombre |

---

## 8. Integración con n8n y MCP

- El servidor MCP (`mcp-server/app/tools/rag.py`) llama a
  `unab.buscar_conocimiento` con el embedding de la consulta y, si no hay
  proveedor de embeddings disponible (OpenAI, Gemini o Cohere), cae
  automáticamente a búsqueda por texto.
- El workflow **WF01** expone esa herramienta al agente mediante el nodo
  **MCP Client Tool**; no necesita el nodo PGVector nativo de n8n.
- Si prefieres el nodo nativo, la tabla ya es compatible:
  `unab.documentos_vectoriales (id, content, metadata, embedding)`.

---

## 9. Evidencia y detalle técnico

- [`docs/04-rag-detalle.md`](../docs/04-rag-detalle.md): justificación de
  `MAX_CHARS`, `MIN_CHARS`, `OVERLAP_CHARS`, HNSW y del modelo único.
- [`rag/evidencias/recuperacion_ejemplo.json`](evidencias/recuperacion_ejemplo.json):
  salida real de «¿Qué prerrequisitos bloquean Cálculo Multivariado?» con los
  5 fragmentos y sus scores.
- [`database/evidencias/verificacion_supabase.txt`](../database/evidencias/verificacion_supabase.txt):
  conteos, caso estrella y `EXPLAIN ANALYZE` del índice vectorial.
