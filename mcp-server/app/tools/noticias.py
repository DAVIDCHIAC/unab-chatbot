"""Herramientas de consulta de noticias y convocatorias."""

from __future__ import annotations

from ..core import mcp
from ..db import fetch_all
from ..utils import limitar, ok


@mcp.tool()
def consultar_noticias(
    texto: str | None = None,
    categoria: str | None = None,
    limite: int = 5,
) -> str:
    """Consulta noticias, convocatorias, becas y eventos recientes de la UNAB.

    Args:
        texto: Palabra o frase a buscar en el título o resumen. Opcional.
        categoria: Filtra por categoría: convocatoria, noticia, evento,
            beca o curso. Opcional.
        limite: Número máximo de noticias (1-20).
    """
    limite = limitar(limite, 1, 20)
    texto = (texto or "").strip() or None
    categoria = (categoria or "").strip().lower() or None
    patron = f"%{texto}%" if texto else None

    rows = fetch_all(
        """
        SELECT id, titulo, resumen, url, fuente, categoria,
               fecha_publicacion, dias_publicada
        FROM unab.v_noticias_recientes
        WHERE (%s::text IS NULL OR titulo ILIKE %s OR COALESCE(resumen, '') ILIKE %s)
          AND (%s::text IS NULL OR categoria = %s)
        ORDER BY fecha_publicacion DESC
        LIMIT %s
        """,
        (texto, patron, patron, categoria, categoria, limite),
    )

    return ok(
        filtros={"texto": texto, "categoria": categoria},
        total=len(rows),
        noticias=rows,
    )
