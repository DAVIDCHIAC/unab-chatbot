"""Herramientas de consulta del calendario académico."""

from __future__ import annotations

from ..core import mcp
from ..db import fetch_all, fetch_one
from ..utils import limitar, ok


@mcp.tool()
def consultar_calendario(
    texto: str | None = None,
    categoria: str | None = None,
    limite: int = 10,
) -> str:
    """Consulta los próximos eventos del calendario académico de la UNAB.

    Sirve para fechas de matrícula, exámenes, inicio de clases, pagos, etc.

    Args:
        texto: Palabra o frase a buscar (ej. "matrícula", "exámenes"). Opcional.
        categoria: Filtra por categoría: matricula, examenes, clases, pagos,
            ceremonia o general. Opcional.
        limite: Número máximo de eventos (1-50).
    """
    limite = limitar(limite, 1, 50)
    texto = (texto or "").strip() or None
    categoria = (categoria or "").strip().lower() or None
    patron = f"%{texto}%" if texto else None

    rows = fetch_all(
        """
        SELECT id, periodo, evento, categoria, fecha_inicio, fecha_fin,
               descripcion, dias_faltantes
        FROM unab.v_calendario_proximo
        WHERE (%s::text IS NULL OR evento ILIKE %s OR COALESCE(descripcion, '') ILIKE %s)
          AND (%s::text IS NULL OR categoria = %s)
        ORDER BY fecha_inicio
        LIMIT %s
        """,
        (texto, patron, patron, categoria, categoria, limite),
    )

    return ok(
        filtros={"texto": texto, "categoria": categoria},
        total=len(rows),
        eventos=rows,
    )


@mcp.tool()
def obtener_periodo_activo() -> str:
    """Devuelve el periodo académico activo y sus fechas de inicio y fin."""
    row = fetch_one(
        """
        SELECT codigo, nombre, fecha_inicio, fecha_fin
        FROM unab.periodos_academicos
        WHERE activo = TRUE
        ORDER BY codigo DESC
        LIMIT 1
        """
    )
    if not row:
        return ok(periodo=None, mensaje="No hay un periodo marcado como activo.")
    return ok(periodo=row)
