"""Herramientas de identificación del estudiante."""

from __future__ import annotations

from ..core import mcp
from ..db import fetch_one
from ..utils import no_encontrado, ok


@mcp.tool()
def identificar_estudiante(identificador: str) -> str:
    """Identifica a un estudiante UNAB por código, documento o correo.

    Úsala SIEMPRE antes de consultar historial, notas o estado académico.
    Devuelve el código UNAB que necesitan las demás herramientas.

    Args:
        identificador: Código UNAB (ej. 10045234), cédula o correo institucional.
    """
    identificador = (identificador or "").strip()
    if not identificador:
        return no_encontrado(
            "Debes indicar un código UNAB, número de documento o correo."
        )

    row = fetch_one(
        """
        SELECT e.id_estudiante,
               e.documento,
               e.nombre || ' ' || e.apellido AS nombre_completo,
               e.email,
               e.semestre_actual,
               e.estado,
               p.nombre AS programa
        FROM unab.estudiantes e
        LEFT JOIN unab.programas p ON p.id_programa = e.id_programa
        WHERE e.id_estudiante = %s
           OR e.documento = %s
           OR lower(e.email) = lower(%s)
        LIMIT 1
        """,
        (identificador, identificador, identificador),
    )

    if not row:
        return no_encontrado(
            "No se encontró un estudiante con ese dato. "
            "Verifica el código o pide el correo institucional.",
            identificador=identificador,
        )

    return ok(estudiante=row)


@mcp.tool()
def listar_programas() -> str:
    """Lista los programas académicos disponibles y sus créditos totales."""
    from ..db import fetch_all

    rows = fetch_all(
        """
        SELECT codigo, nombre, facultad, creditos_totales, semestres_totales
        FROM unab.programas
        WHERE activo = TRUE
        ORDER BY nombre
        """
    )
    return ok(total=len(rows), programas=rows)
