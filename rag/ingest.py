#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pipeline de ingesta RAG del Chatbot de Apoyo Académico UNAB.

Lee los documentos Markdown de ``rag/documentos``, los divide en chunks con
*overlap* opcional, genera embeddings (Gemini, Cohere u OpenAI) y los guarda en
Supabase/PostgreSQL (``unab.documentos_vectoriales``). Cada chunk registra en
sus metadatos el modelo y las dimensiones usadas, para garantizar que la
colección sea homogénea.

Uso:
    python ingest.py --stats
    python ingest.py --reembed          # rellena embeddings NULL (rápido)
    python ingest.py --reindex          # reprocesa todos los .md
    python ingest.py --file documentos/faq_academica.md
    python ingest.py --reindex --dry-run

Requisitos:
    pip install -r requirements.txt
    cp .env.example .env  (y completar credenciales)
"""

from __future__ import annotations

import argparse
import hashlib
import logging
import os
import re
import sys
import time
from datetime import date
from pathlib import Path

import psycopg2
from psycopg2.extras import Json, execute_values

try:
    from dotenv import load_dotenv

    load_dotenv(Path(__file__).with_name(".env"))
except ImportError:  # python-dotenv es opcional
    pass

try:
    from openai import OpenAI
except ImportError:
    OpenAI = None  # type: ignore[assignment]

BASE_DIR = Path(__file__).resolve().parent
DOCS_DIR = Path(os.getenv("RAG_DOCS_DIR", BASE_DIR / "documentos"))

# --- Proveedor de embeddings ------------------------------------------------
# EMBEDDING_PROVIDER: "openai" | "gemini" | vacío (autodetecta por la clave).
PROVIDER = os.getenv("EMBEDDING_PROVIDER", "").strip().lower()
OPENAI_MODEL = os.getenv("OPENAI_EMBEDDING_MODEL", "text-embedding-3-small")
GEMINI_MODEL = os.getenv("GEMINI_EMBEDDING_MODEL", "gemini-embedding-001")
GEMINI_BASE_URL = os.getenv(
    "GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta"
)
COHERE_MODEL = os.getenv("COHERE_EMBEDDING_MODEL", "embed-v4.0")
COHERE_BASE_URL = os.getenv("COHERE_BASE_URL", "https://api.cohere.com/v2")
DIMS = int(os.getenv("EMBEDDING_DIMENSIONS", "1536"))
BATCH_SIZE = int(os.getenv("RAG_BATCH_SIZE", "64"))
MAX_CHARS = int(os.getenv("RAG_MAX_CHARS", "1400"))
MIN_CHARS = int(os.getenv("RAG_MIN_CHARS", "40"))
# Solapamiento entre chunks consecutivos: conserva el contexto que queda en el
# borde y evita que una respuesta quede cortada a mitad de una idea.
OVERLAP_CHARS = int(os.getenv("RAG_OVERLAP_CHARS", "160"))

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO").upper(),
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger("unab-rag")


# ---------------------------------------------------------------------------
# Lectura y chunking
# ---------------------------------------------------------------------------
def parse_front_matter(raw: str) -> tuple[dict[str, str], str]:
    """Extrae un front matter sencillo ``--- clave: valor ---``."""
    meta: dict[str, str] = {}
    match = re.match(r"^---\s*\n(.*?)\n---\s*\n", raw, re.S)
    if not match:
        return meta, raw
    for line in match.group(1).splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            meta[key.strip().lower()] = value.strip()
    return meta, raw[match.end():]


def split_long(text: str, max_chars: int) -> list[str]:
    """Divide un párrafo largo respetando el final de las oraciones."""
    if len(text) <= max_chars:
        return [text]

    sentences = re.split(r"(?<=[.!?])\s+", text)
    pieces: list[str] = []
    current = ""
    for sentence in sentences:
        if len(current) + len(sentence) + 1 <= max_chars:
            current = f"{current} {sentence}".strip()
        else:
            if current:
                pieces.append(current)
            current = sentence
    if current:
        pieces.append(current)

    result: list[str] = []
    for piece in pieces:
        while len(piece) > max_chars:
            result.append(piece[:max_chars].strip())
            piece = piece[max_chars:]
        if piece.strip():
            result.append(piece.strip())
    return result


def aplicar_overlap(chunks: list[str], overlap: int, max_chars: int) -> list[str]:
    """Antepone el final del chunk anterior a cada chunk siguiente.

    El prefijo nunca supera ``overlap`` caracteres ni hace que el chunk
    resultante exceda ``max_chars``. Se recorta en espacio en blanco para no
    partir palabras.
    """
    if overlap <= 0 or len(chunks) < 2:
        return chunks

    salida: list[str] = [chunks[0]]
    for chunk in chunks[1:]:
        disponible = min(overlap, max_chars - len(chunk) - 1)
        if disponible > 40:
            cola = salida[-1][-disponible:].strip()
            corte = cola.find(" ")
            if 0 < corte < len(cola) // 2:
                cola = cola[corte + 1 :].strip()
            if cola:
                chunk = f"{cola}\n{chunk}"
        salida.append(chunk)
    return salida


def chunk_document(
    body: str,
    *,
    max_chars: int = MAX_CHARS,
    min_chars: int = MIN_CHARS,
    overlap: int = OVERLAP_CHARS,
) -> list[str]:
    """Convierte el cuerpo Markdown en chunks por párrafo con solapamiento."""
    chunks: list[str] = []
    for block in re.split(r"\n\s*\n", body):
        block = block.strip()
        if not block or block.startswith("#") or block.startswith("<!--"):
            continue
        block = re.sub(r"^[-*+]\s+", "", block, flags=re.M)
        block = re.sub(r"[ \t]+", " ", block)
        if len(block) < min_chars:
            continue
        chunks.extend(split_long(block, max_chars))
    return aplicar_overlap(chunks, overlap, max_chars)


def load_document(path: Path) -> tuple[str, dict[str, str], list[str], str]:
    raw = path.read_text(encoding="utf-8")
    meta, body = parse_front_matter(raw)
    titulo = meta.get("titulo") or path.stem.replace("_", " ").title()
    categoria = meta.get("categoria", "institucional")
    digest = hashlib.sha256(raw.encode("utf-8")).hexdigest()
    chunks = chunk_document(body)
    return titulo, {"categoria": categoria}, chunks, digest


# ---------------------------------------------------------------------------
# Base de datos
# ---------------------------------------------------------------------------
def connect():
    url = os.getenv("DATABASE_URL")
    try:
        if url:
            return psycopg2.connect(url, connect_timeout=20)
        return psycopg2.connect(
            host=os.getenv("PGHOST", "127.0.0.1"),
            port=int(os.getenv("PGPORT", "5432")),
            dbname=os.getenv("PGDATABASE", "postgres"),
            user=os.getenv("PGUSER", "postgres"),
            password=os.getenv("PGPASSWORD", ""),
            sslmode=os.getenv("PGSSLMODE", "prefer"),
            connect_timeout=20,
        )
    except psycopg2.Error as exc:
        log.error("No se pudo conectar a la base de datos: %s", exc)
        sys.exit(1)


def vector_literal(values: list[float]) -> str:
    return "[" + ",".join(f"{v:.6f}" for v in values) + "]"


def stats(conn) -> None:
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT COUNT(*)                                        AS chunks,
                   COUNT(*) FILTER (WHERE embedding IS NOT NULL)   AS con_embedding,
                   COUNT(*) FILTER (WHERE embedding IS NULL)       AS sin_embedding,
                   COUNT(DISTINCT metadata->>'fuente')             AS fuentes
            FROM unab.documentos_vectoriales
            """
        )
        chunks, con_emb, sin_emb, fuentes = cur.fetchone()
        cur.execute("SELECT COUNT(*) FROM unab.documentos")
        documentos = cur.fetchone()[0]

    log.info("Documentos en catálogo : %s", documentos)
    log.info("Fuentes distintas       : %s", fuentes)
    log.info("Chunks totales          : %s", chunks)
    log.info("Chunks con embedding    : %s", con_emb)
    log.info("Chunks sin embedding    : %s", sin_emb)
    if sin_emb:
        log.info("Sugerencia: python ingest.py --reembed")


# ---------------------------------------------------------------------------
# Embeddings (OpenAI o Gemini)
# ---------------------------------------------------------------------------
class OpenAIEmbedder:
    nombre = "openai"
    modelo = OPENAI_MODEL

    def __init__(self, api_key: str) -> None:
        if OpenAI is None:
            log.error("Falta el paquete 'openai'. Ejecuta: pip install -r requirements.txt")
            sys.exit(1)
        self.client = OpenAI(api_key=api_key)

    def embed(self, texts: list[str], tipo: str) -> list[list[float]]:
        kwargs = {"model": OPENAI_MODEL, "input": texts}
        if OPENAI_MODEL.startswith("text-embedding-3"):
            kwargs["dimensions"] = DIMS
        response = self.client.embeddings.create(**kwargs)
        return [item.embedding for item in response.data]


class GeminiEmbedder:
    """Embeddings de Google AI Studio (cuota gratuita)."""

    nombre = "gemini"
    modelo = GEMINI_MODEL
    MAX_POR_PETICION = 100

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key

    def _lote(self, texts: list[str], tipo: str) -> list[list[float]]:
        import httpx

        tarea = "RETRIEVAL_DOCUMENT" if tipo == "documento" else "RETRIEVAL_QUERY"
        peticiones = [
            {
                "model": f"models/{GEMINI_MODEL}",
                "content": {"parts": [{"text": texto[:8000]}]},
                "taskType": tarea,
            }
            for texto in texts
        ]
        if GEMINI_MODEL.startswith("gemini-embedding"):
            for peticion in peticiones:
                peticion["outputDimensionality"] = DIMS

        with httpx.Client(timeout=90) as client:
            response = client.post(
                f"{GEMINI_BASE_URL}/models/{GEMINI_MODEL}:batchEmbedContents",
                headers={
                    "x-goog-api-key": self.api_key,
                    "Content-Type": "application/json",
                },
                json={"requests": peticiones},
            )
            response.raise_for_status()
            data = response.json()
        return [item["values"] for item in data.get("embeddings", [])]

    def embed(self, texts: list[str], tipo: str) -> list[list[float]]:
        vectores: list[list[float]] = []
        for inicio in range(0, len(texts), self.MAX_POR_PETICION):
            vectores.extend(
                self._lote(texts[inicio : inicio + self.MAX_POR_PETICION], tipo)
            )
        return vectores


class CohereEmbedder:
    """Embeddings de Cohere (trial gratuito, embed-v4.0 a 1536 dimensiones)."""

    nombre = "cohere"
    modelo = COHERE_MODEL
    MAX_POR_PETICION = 96

    def __init__(self, api_key: str) -> None:
        self.api_key = api_key

    def _lote(self, texts: list[str], tipo: str) -> list[list[float]]:
        import httpx

        entrada = "search_document" if tipo == "documento" else "search_query"
        with httpx.Client(timeout=90) as client:
            response = client.post(
                f"{COHERE_BASE_URL}/embed",
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": COHERE_MODEL,
                    "texts": [texto[:8000] for texto in texts],
                    "input_type": entrada,
                    "embedding_types": ["float"],
                    "output_dimension": DIMS,
                },
            )
            response.raise_for_status()
            data = response.json()
        return data.get("embeddings", {}).get("float", [])

    def embed(self, texts: list[str], tipo: str) -> list[list[float]]:
        vectores: list[list[float]] = []
        for inicio in range(0, len(texts), self.MAX_POR_PETICION):
            vectores.extend(
                self._lote(texts[inicio : inicio + self.MAX_POR_PETICION], tipo)
            )
        return vectores


def make_embedder():
    """Devuelve el embedder configurado (OpenAI, Gemini o Cohere)."""
    clave_openai = os.getenv("OPENAI_API_KEY") or ""
    clave_gemini = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY") or ""
    clave_cohere = os.getenv("COHERE_API_KEY") or ""

    proveedor = PROVIDER
    if proveedor not in {"openai", "gemini", "cohere"}:
        # Autodetección: OpenAI primero, Gemini después, Cohere al final.
        proveedor = (
            "openai"
            if clave_openai
            else ("gemini" if clave_gemini else ("cohere" if clave_cohere else ""))
        )

    if proveedor == "openai":
        if not clave_openai:
            log.error("EMBEDDING_PROVIDER=openai pero falta OPENAI_API_KEY")
            sys.exit(1)
        return OpenAIEmbedder(clave_openai)

    if proveedor == "gemini":
        if not clave_gemini:
            log.error("EMBEDDING_PROVIDER=gemini pero falta GEMINI_API_KEY")
            sys.exit(1)
        return GeminiEmbedder(clave_gemini)

    if proveedor == "cohere":
        if not clave_cohere:
            log.error("EMBEDDING_PROVIDER=cohere pero falta COHERE_API_KEY")
            sys.exit(1)
        return CohereEmbedder(clave_cohere)

    log.error(
        "No hay proveedor de embeddings. Define GEMINI_API_KEY, COHERE_API_KEY u "
        "OPENAI_API_KEY, o EMBEDDING_PROVIDER=openai|gemini|cohere."
    )
    sys.exit(1)


def embed_texts(embedder, texts: list[str], *, tipo: str = "documento") -> list[list[float]]:
    """Genera embeddings con reintentos exponenciales."""
    last_error: Exception | None = None
    for attempt in range(1, 4):
        try:
            vectors = embedder.embed(texts, tipo)
            if len(vectors) != len(texts):
                raise RuntimeError(
                    f"{embedder.nombre} devolvió un número distinto de embeddings"
                )
            for vector in vectors:
                if len(vector) != DIMS:
                    raise RuntimeError(
                        f"embedding de {len(vector)} dimensiones, se esperaban {DIMS}"
                    )
            return vectors
        except Exception as exc:  # noqa: BLE001
            last_error = exc
            wait = 2**attempt
            log.warning("Error de embeddings (intento %s/3): %s", attempt, exc)
            if attempt < 3:
                time.sleep(wait)
    raise RuntimeError(f"No se pudieron generar los embeddings: {last_error}")


def reembed(conn, embedder, limit: int | None = None) -> int:
    """Rellena los embeddings que estén en NULL."""
    total = 0
    with conn.cursor() as cur:
        while True:
            batch = BATCH_SIZE if limit is None else min(BATCH_SIZE, limit - total)
            if batch <= 0:
                break
            cur.execute(
                """
                SELECT id, content
                FROM unab.documentos_vectoriales
                WHERE embedding IS NULL AND content IS NOT NULL AND length(content) > 0
                ORDER BY id
                LIMIT %s
                """,
                (batch,),
            )
            rows = cur.fetchall()
            if not rows:
                break
            vectors = embed_texts(embedder, [row[1] for row in rows])
            for (row_id, _), vector in zip(rows, vectors):
                cur.execute(
                    "UPDATE unab.documentos_vectoriales SET embedding = %s::vector WHERE id = %s",
                    (vector_literal(vector), row_id),
                )
            conn.commit()
            total += len(rows)
            log.info("Embeddings actualizados: %s", total)
            if limit is not None and total >= limit:
                break

    # Marca como procesados los documentos cuyos chunks ya tienen embedding.
    with conn.cursor() as cur:
        cur.execute(
            """
            UPDATE unab.documentos d
               SET procesado = TRUE,
                   updated_at = NOW()
             WHERE EXISTS (
                       SELECT 1 FROM unab.documentos_vectoriales v
                        WHERE v.metadata->>'fuente' = d.fuente
                   )
               AND NOT EXISTS (
                       SELECT 1 FROM unab.documentos_vectoriales v
                        WHERE v.metadata->>'fuente' = d.fuente
                          AND v.embedding IS NULL
                   )
               AND d.procesado IS NOT TRUE
            """
        )
        if cur.rowcount:
            log.info("Documentos marcados como procesados: %s", cur.rowcount)
    conn.commit()
    return total


def ingest_file(conn, embedder, path: Path, *, replace: bool = True) -> int:
    titulo, meta, chunks, digest = load_document(path)
    fuente = path.name
    if not chunks:
        log.warning("%s no produjo chunks; se omite", fuente)
        return 0

    log.info("Procesando %s (%s chunks)", fuente, len(chunks))
    vectors = embed_texts(embedder, chunks)
    today = date.today().isoformat()

    with conn.cursor() as cur:
        if replace:
            cur.execute(
                "DELETE FROM unab.documentos_vectoriales WHERE metadata->>'fuente' = %s",
                (fuente,),
            )

        rows = [
            (
                chunk,
                Json(
                    {
                        "fuente": fuente,
                        "titulo": titulo,
                        "categoria": meta["categoria"],
                        "chunk": index + 1,
                        "hash": digest,
                        "actualizado": today,
                        "modelo": f"{embedder.nombre}:{embedder.modelo}",
                        "dimensiones": DIMS,
                        "overlap": OVERLAP_CHARS,
                    }
                ),
                vector_literal(vector),
            )
            for index, (chunk, vector) in enumerate(zip(chunks, vectors))
        ]
        execute_values(
            cur,
            """
            INSERT INTO unab.documentos_vectoriales (content, metadata, embedding)
            VALUES %s
            """,
            rows,
            template="(%s, %s, %s::vector)",
            page_size=100,
        )

        cur.execute(
            """
            INSERT INTO unab.documentos
                (titulo, fuente, tipo, categoria, version, hash_contenido,
                 num_chunks, procesado)
            VALUES (%s, %s, 'markdown', %s, '1.0', %s, %s, TRUE)
            ON CONFLICT (fuente) DO UPDATE SET
                titulo         = EXCLUDED.titulo,
                categoria      = EXCLUDED.categoria,
                hash_contenido = EXCLUDED.hash_contenido,
                num_chunks     = EXCLUDED.num_chunks,
                procesado      = TRUE,
                updated_at     = NOW()
            """,
            (titulo, fuente, meta["categoria"], digest, len(chunks)),
        )
    conn.commit()
    log.info("OK %s: %s chunks con embedding", fuente, len(chunks))
    return len(chunks)


def ingest_all(conn, embedder) -> int:
    files = sorted(DOCS_DIR.glob("*.md"))
    if not files:
        log.error("No hay archivos .md en %s", DOCS_DIR)
        return 0
    total = 0
    for path in files:
        total += ingest_file(conn, embedder, path)
    return total


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Ingesta de documentos institucionales al RAG de la UNAB."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--reembed", action="store_true", help="Rellena embeddings NULL.")
    group.add_argument("--reindex", action="store_true", help="Reingesta todos los .md.")
    group.add_argument("--file", type=Path, help="Reingesta un único archivo .md.")
    group.add_argument("--stats", action="store_true", help="Muestra el estado del RAG.")
    parser.add_argument("--dry-run", action="store_true", help="Solo muestra el chunking.")
    parser.add_argument("--limit", type=int, default=None, help="Máximo de chunks a procesar.")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    if not (args.reembed or args.reindex or args.file or args.stats):
        args.reembed = True  # comportamiento por defecto: completar lo que falte

    if args.dry_run:
        files = [args.file] if args.file else sorted(DOCS_DIR.glob("*.md"))
        for path in files:
            if not path.is_absolute():
                path = DOCS_DIR / path
            titulo, meta, chunks, _ = load_document(path)
            print(f"\n{path.name} | {titulo} | categoria={meta['categoria']} | {len(chunks)} chunks")
            for index, chunk in enumerate(chunks, 1):
                print(f"  [{index}] ({len(chunk)} chars) {chunk[:90]}...")
        return 0

    conn = connect()
    try:
        if args.stats:
            stats(conn)
            return 0

        embedder = make_embedder()

        if args.reindex:
            total = ingest_all(conn, embedder)
        elif args.file:
            path = args.file if args.file.is_absolute() else DOCS_DIR / args.file
            if not path.exists():
                log.error("No existe el archivo %s", path)
                return 1
            total = ingest_file(conn, embedder, path)
        else:
            total = reembed(conn, embedder, limit=args.limit)

        log.info("Proceso terminado. Chunks procesados: %s", total)
        stats(conn)
        return 0
    finally:
        conn.close()


if __name__ == "__main__":
    raise SystemExit(main())
