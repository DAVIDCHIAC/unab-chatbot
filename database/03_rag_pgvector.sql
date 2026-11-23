-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 03_rag_pgvector.sql
-- DESCRIPCIÓN:
--   Habilita pgvector y crea la infraestructura RAG:
--     - unab.documentos            (catálogo de fuentes)
--     - unab.documentos_vectoriales (chunks + embeddings, compatible n8n)
--     - Índices HNSW (cosine) y GIN (metadata)
--     - Función unab.buscar_conocimiento(...) para consultas SQL directas
--     - Columna embedding en unab.noticias para búsqueda semántica
--
--   Compatible con el nodo nativo de n8n "Postgres PGVector Store"
--   (columnas: id uuid, content text, metadata jsonb, embedding vector(1536)).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Extensión pgvector
--    En Supabase suele venir instalada en el esquema "extensions".
--    Si tu proyecto la tiene en public, este comando no hace nada.
-- ----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS vector;

-- ----------------------------------------------------------------------------
-- 2. Catálogo de documentos (control de ingesta)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.documentos (
    id             SERIAL PRIMARY KEY,
    titulo         VARCHAR(250) NOT NULL,
    fuente         VARCHAR(250) NOT NULL UNIQUE,  -- nombre del archivo o URL
    tipo           VARCHAR(40) DEFAULT 'markdown',-- markdown | pdf | web | faq
    categoria      VARCHAR(60) DEFAULT 'institucional',
    version        VARCHAR(20) DEFAULT '1.0',
    hash_contenido VARCHAR(64),
    num_chunks     INT DEFAULT 0,
    procesado      BOOLEAN DEFAULT FALSE,
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE unab.documentos IS 'Registro de documentos cargados al pipeline RAG';

-- ----------------------------------------------------------------------------
-- 3. Tabla vectorial (compatible con n8n / LangChain)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.documentos_vectoriales (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content    TEXT,
    metadata   JSONB DEFAULT '{}'::jsonb,
    embedding  vector(1536)
);

COMMENT ON TABLE unab.documentos_vectoriales IS 'Chunks con embeddings de 1536 dimensiones generados con gemini-embedding-001 (modelo registrado en metadata)';

-- Índice HNSW por distancia coseno (mejor recall que ivfflat para RAG)
CREATE INDEX IF NOT EXISTS idx_doc_vec_embedding_hnsw
    ON unab.documentos_vectoriales
    USING hnsw (embedding vector_cosine_ops);

-- Índice para filtrar por fuente/categoría
CREATE INDEX IF NOT EXISTS idx_doc_vec_metadata
    ON unab.documentos_vectoriales
    USING gin (metadata);

-- ----------------------------------------------------------------------------
-- 4. Función de búsqueda semántica
--    Uso desde SQL / MCP / n8n (Postgres node):
--      SELECT * FROM unab.buscar_conocimiento(
--        '[0.01, 0.02, ...]'::vector, 5, '{"fuente":"FAQ.md"}'::jsonb
--      );
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unab.buscar_conocimiento(
    query_embedding vector(1536),
    match_count     INT DEFAULT 5,
    filtro          JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE (
    id         UUID,
    contenido  TEXT,
    metadata   JSONB,
    similitud  DOUBLE PRECISION
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        d.id,
        d.content,
        d.metadata,
        (1 - (d.embedding <=> query_embedding))::DOUBLE PRECISION AS similitud
    FROM unab.documentos_vectoriales d
    WHERE d.embedding IS NOT NULL
      AND (filtro = '{}'::jsonb OR d.metadata @> filtro)
    ORDER BY d.embedding <=> query_embedding
    LIMIT LEAST(GREATEST(match_count, 1), 50);
$$;

COMMENT ON FUNCTION unab.buscar_conocimiento IS
    'Búsqueda vectorial por similitud coseno con filtro opcional de metadata';

-- ----------------------------------------------------------------------------
-- 5. Embeddings para noticias (búsqueda semántica de convocatorias)
-- ----------------------------------------------------------------------------
ALTER TABLE unab.noticias ADD COLUMN IF NOT EXISTS embedding vector(1536);

CREATE INDEX IF NOT EXISTS idx_noticias_embedding_hnsw
    ON unab.noticias
    USING hnsw (embedding vector_cosine_ops);

-- ----------------------------------------------------------------------------
-- 6. Trigger updated_at para documentos
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_documentos_updated ON unab.documentos;
CREATE TRIGGER trg_documentos_updated
    BEFORE UPDATE ON unab.documentos
    FOR EACH ROW EXECUTE FUNCTION unab.fn_set_updated_at();

-- ----------------------------------------------------------------------------
-- 7. Verificación
-- ----------------------------------------------------------------------------
SELECT 'documentos_vectoriales' AS tabla, COUNT(*) AS registros
FROM unab.documentos_vectoriales;

-- ============================================================================
-- FIN 03_rag_pgvector.sql
-- ============================================================================
