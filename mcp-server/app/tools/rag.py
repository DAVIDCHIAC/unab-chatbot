"""Herramientas RAG sobre la base de conocimiento institucional."""

from __future__ import annotations

import logging

from ..core import mcp
from ..db import fetch_all, fetch_one
from ..embeddings import EmbeddingError, embed, to_pgvector
from ..utils import limitar, ok, to_json

logger = logging.getLogger(__name__)


def _buscar_por_texto(consulta: str, limite: int, fuente: str | None) -> list[dict]:
    """Fallback sin embeddings: búsqueda full-text en español + ILIKE."""
    rows = fetch_all(
        """
        SELECT id, content AS contenido, metadata,
               ts_rank(
                   to_tsvector('spanish', COALESCE(content, '')),
                   plainto_tsquery('spanish', %s)
               )::DOUBLE PRECISION AS similitud
        FROM unab.documentos_vectoriales
        WHERE (%s::text IS NULL OR metadata->>'fuente' = %s)
          AND to_tsvector('spanish', COALESCE(content, ''))
              @@ plainto_tsquery('spanish', %s)
        ORDER BY similitud DESC
        LIMIT %s
        """,
        (consulta, fuente, fuente, consulta, limite),
    )
    if rows:
        return rows

    return fetch_all(
        """
        SELECT id, content AS contenido, metadata, 0.0::DOUBLE PRECISION AS similitud
        FROM unab.documentos_vectoriales
        WHERE (%s::text IS NULL OR metadata->>'fuente' = %s)
          AND content ILIKE %s
        LIMIT %s
        """,
        (fuente, fuente, f"%{consulta}%", limite),
    )


def _aplanar(rows: list[dict]) -> list[dict]:
    """Convierte las filas SQL en resultados planos y fáciles de citar."""
    resultados: list[dict] = []
    for fila in rows:
        meta = fila.get("metadata") or {}
        similitud = fila.get("similitud")
        resultados.append(
            {
                "id": str(fila.get("id")) if fila.get("id") is not None else None,
                "contenido": fila.get("contenido"),
                "titulo": meta.get("titulo"),
                "fuente": meta.get("fuente"),
                "categoria": meta.get("categoria"),
                "url": meta.get("url"),
                "score": round(float(similitud), 4) if similitud is not None else 0.0,
            }
        )
    return resultados


@mcp.tool()
def buscar_conocimiento_institucional(
    consulta: str,
    limite: int = 5,
    fuente: str | None = None,
) -> str:
    """Busca en los documentos oficiales de la UNAB (reglamento, CCD, FAQ).

    Usa búsqueda vectorial (pgvector) y, si no hay proveedor de embeddings
    configurado (OpenAI o Gemini), cae automáticamente a búsqueda por texto.
    Devuelve los fragmentos más relevantes con su fuente y un contexto listo
    para citar.

    Args:
        consulta: Pregunta o tema a buscar (ej. "requisitos de grado").
        limite: Número de fragmentos a recuperar (1-10).
        fuente: Filtra por nombre de archivo o documento. Opcional.
    """
    consulta = (consulta or "").strip()
    if not consulta:
        return ok(modo="ninguno", total=0, resultados=[], contexto="")

    limite = limitar(limite, 1, 10)
    fuente = (fuente or "").strip() or None
    modo = "vectorial"

    try:
        vector = embed(consulta)
        filtro = {"fuente": fuente} if fuente else {}
        rows = fetch_all(
            """
            SELECT id, contenido, metadata, similitud
            FROM unab.buscar_conocimiento(%s::vector, %s, %s::jsonb)
            """,
            (to_pgvector(vector), limite, _json(filtro)),
        )
        if not rows:
            modo = "texto"
            rows = _buscar_por_texto(consulta, limite, fuente)
    except EmbeddingError as exc:
        logger.warning("Embedding no disponible, usando búsqueda por texto: %s", exc)
        modo = "texto"
        rows = _buscar_por_texto(consulta, limite, fuente)
    except Exception as exc:  # pragma: no cover - errores de BD
        logger.exception("Error en la búsqueda RAG")
        return to_json(
            {
                "status": "error",
                "mensaje": f"No se pudo consultar la base de conocimiento: {exc}",
                "resultados": [],
            }
        )

    contexto = "\n\n".join(
        f"[{index + 1}] {fila.get('contenido', '')[:1200]}"
        for index, fila in enumerate(rows)
    )[:7000]

    return ok(
        modo=modo,
        consulta=consulta,
        total=len(rows),
        resultados=_aplanar(rows),
        contexto=contexto,
    )


@mcp.tool()
def estadisticas_conocimiento() -> str:
    """Indica cuántos documentos y fragmentos hay cargados para el RAG."""
    resumen = fetch_one(
        """
        SELECT COUNT(*)                                        AS chunks,
               COUNT(*) FILTER (WHERE embedding IS NOT NULL)   AS con_embedding,
               COUNT(DISTINCT metadata->>'fuente')             AS fuentes
        FROM unab.documentos_vectoriales
        """
    )
    documentos = fetch_all(
        """
        SELECT titulo, fuente, categoria, num_chunks, procesado, updated_at
        FROM unab.documentos
        ORDER BY updated_at DESC
        LIMIT 20
        """
    )
    return ok(resumen=resumen, documentos=documentos)


def _json(data: dict) -> str:
    import json

    return json.dumps(data, ensure_ascii=False)
