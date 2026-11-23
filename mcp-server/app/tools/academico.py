"""Herramientas de historial, avance, proyección y recomendación académica."""

from __future__ import annotations

from ..core import mcp
from ..db import fetch_all, fetch_one
from ..utils import limitar, no_encontrado, ok, to_json


def _existe_estudiante(id_estudiante: str) -> bool:
    row = fetch_one(
        "SELECT 1 AS ok FROM unab.estudiantes WHERE id_estudiante = %s",
        (id_estudiante,),
    )
    return row is not None


@mcp.tool()
def obtener_estado_academico(id_estudiante: str) -> str:
    """Devuelve el estado académico completo de un estudiante.

    Incluye programa, semestre, promedio, créditos aprobados, porcentaje de
    avance, proyección de semestres restantes y alertas de riesgo.

    Args:
        id_estudiante: Código UNAB del estudiante (ej. 10045234).
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return no_encontrado("Falta el código del estudiante.")

    estado = fetch_one(
        "SELECT * FROM unab.v_estado_estudiante WHERE id_estudiante = %s",
        (id_estudiante,),
    )
    if not estado:
        return no_encontrado("No existe un estudiante con ese código.")

    avance = fetch_one(
        "SELECT * FROM unab.v_avance_plan WHERE id_estudiante = %s",
        (id_estudiante,),
    )
    proyeccion = fetch_one(
        "SELECT * FROM unab.v_proyeccion_semestres WHERE id_estudiante = %s",
        (id_estudiante,),
    )
    alertas = fetch_one(
        "SELECT * FROM unab.v_alertas_academicas WHERE id_estudiante = %s",
        (id_estudiante,),
    )

    return ok(
        estudiante=estado,
        avance=avance,
        proyeccion=proyeccion,
        alertas=alertas or {"alertas": []},
    )


@mcp.tool()
def obtener_historial(
    id_estudiante: str,
    periodo: str | None = None,
    solo_reprobados: bool = False,
    limite: int = 80,
) -> str:
    """Devuelve el historial académico detallado (materias, notas y estados).

    Args:
        id_estudiante: Código UNAB del estudiante.
        periodo: Filtra por periodo, por ejemplo "2025-1". Opcional.
        solo_reprobados: Si es True devuelve únicamente asignaturas reprobadas.
        limite: Número máximo de registros (1-200).
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return no_encontrado("Falta el código del estudiante.")

    limite = limitar(limite, 1, 200)
    rows = fetch_all(
        """
        SELECT codigo_curso, curso, creditos, semestre_sugerido, area,
               periodo, nota, estado, intento
        FROM unab.v_historial_detalle
        WHERE id_estudiante = %s
          AND (%s IS NULL OR periodo = %s)
          AND (%s = FALSE OR estado = 'reprobado')
        ORDER BY periodo, codigo_curso
        LIMIT %s
        """,
        (id_estudiante, periodo, periodo, solo_reprobados, limite),
    )

    if not rows:
        return no_encontrado(
            "El estudiante no tiene registros con esos filtros.",
            id_estudiante=id_estudiante,
        )

    return ok(
        id_estudiante=id_estudiante,
        total=len(rows),
        historial=rows,
    )


@mcp.tool()
def obtener_cursos_pendientes(id_estudiante: str, limite: int = 40) -> str:
    """Lista las asignaturas que el estudiante aún no ha aprobado ni matriculado.

    Args:
        id_estudiante: Código UNAB del estudiante.
        limite: Número máximo de cursos (1-100).
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return no_encontrado("Falta el código del estudiante.")

    limite = limitar(limite, 1, 100)
    rows = fetch_all(
        """
        SELECT codigo_curso, curso_pendiente, creditos, semestre_sugerido,
               tipo, area
        FROM unab.v_cursos_pendientes
        WHERE id_estudiante = %s
        ORDER BY semestre_sugerido, codigo_curso
        LIMIT %s
        """,
        (id_estudiante, limite),
    )
    return ok(id_estudiante=id_estudiante, total=len(rows), cursos_pendientes=rows)


@mcp.tool()
def obtener_prerrequisitos_pendientes(id_estudiante: str) -> str:
    """Lista los cursos bloqueados porque su prerrequisito no está aprobado.

    Devuelve el curso bloqueado, el prerrequisito y el motivo
    (reprobado, pendiente o en curso).

    Args:
        id_estudiante: Código UNAB del estudiante.
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return no_encontrado("Falta el código del estudiante.")

    rows = fetch_all(
        """
        SELECT curso_bloqueado, nombre_curso, semestre_sugerido,
               codigo_prerequisito, nombre_prerequisito,
               estado_prerequisito, tipo_bloqueo, nota_prerequisito
        FROM unab.v_prerrequisitos_pendientes
        WHERE id_estudiante = %s
        ORDER BY semestre_sugerido, curso_bloqueado
        """,
        (id_estudiante,),
    )
    return ok(
        id_estudiante=id_estudiante,
        total=len(rows),
        cursos_bloqueados=rows,
    )


@mcp.tool()
def proyectar_semestres(id_estudiante: str) -> str:
    """Estima cuántos semestres le faltan al estudiante para graduarse.

    Usa el ritmo real de créditos aprobados por semestre.

    Args:
        id_estudiante: Código UNAB del estudiante.
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return no_encontrado("Falta el código del estudiante.")

    row = fetch_one(
        "SELECT * FROM unab.v_proyeccion_semestres WHERE id_estudiante = %s",
        (id_estudiante,),
    )
    if not row:
        return no_encontrado("No existe un estudiante con ese código.")
    return ok(proyeccion=row)


@mcp.tool()
def recomendar_matricula(id_estudiante: str, max_creditos: int = 18) -> str:
    """Recomienda qué asignaturas matricular el próximo semestre.

    Solo sugiere cursos cuyos prerrequisitos ya estén aprobados y respeta el
    límite de créditos indicado. También informa cuántos cursos quedan
    bloqueados por prerrequisitos.

    Args:
        id_estudiante: Código UNAB del estudiante.
        max_creditos: Créditos máximos a matricular (6-25, por defecto 18).
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return no_encontrado("Falta el código del estudiante.")
    if not _existe_estudiante(id_estudiante):
        return no_encontrado("No existe un estudiante con ese código.")

    max_creditos = limitar(max_creditos, 6, 25)

    rows = fetch_all(
        """
        WITH pendientes AS (
            SELECT c.id_curso, c.codigo_curso, c.nombre, c.creditos,
                   c.semestre_sugerido, c.tipo, c.area,
                   (
                       SELECT COUNT(*)
                       FROM unab.prerrequisitos r
                       LEFT JOIN LATERAL (
                           SELECT h.estado
                           FROM unab.historial_academico h
                           WHERE h.id_estudiante = %s
                             AND h.id_curso = r.id_prerrequisito
                           ORDER BY h.periodo DESC, h.intento DESC
                           LIMIT 1
                       ) h ON TRUE
                       WHERE r.id_curso = c.id_curso
                         AND COALESCE(h.estado, 'pendiente')
                             NOT IN ('aprobado', 'homologado')
                   ) AS prereq_faltantes
            FROM unab.cursos c
            WHERE c.id_programa = (
                    SELECT id_programa FROM unab.estudiantes
                    WHERE id_estudiante = %s
                  )
              AND NOT EXISTS (
                    SELECT 1
                    FROM unab.historial_academico h
                    WHERE h.id_estudiante = %s
                      AND h.id_curso = c.id_curso
                      AND h.estado IN ('aprobado', 'homologado', 'en_curso')
                  )
        )
        SELECT * FROM pendientes
        ORDER BY semestre_sugerido, codigo_curso
        """,
        (id_estudiante, id_estudiante, id_estudiante),
    )

    disponibles = [r for r in rows if r["prereq_faltantes"] == 0]
    bloqueados = [r for r in rows if r["prereq_faltantes"] > 0]

    recomendados: list[dict] = []
    omitidos: list[dict] = []
    creditos = 0
    for curso in disponibles:
        if creditos + curso["creditos"] <= max_creditos:
            recomendados.append(curso)
            creditos += curso["creditos"]
        else:
            omitidos.append(curso)

    semestre = min((c["semestre_sugerido"] for c in recomendados), default=None)

    return to_json(
        {
            "status": "ok",
            "id_estudiante": id_estudiante,
            "max_creditos": max_creditos,
            "creditos_recomendados": creditos,
            "semestre_recomendado": semestre,
            "recomendados": recomendados,
            "omitidos_por_credito": omitidos,
            "cursos_bloqueados": len(bloqueados),
            "detalle_bloqueados": [
                {
                    "codigo_curso": b["codigo_curso"],
                    "nombre": b["nombre"],
                    "prerrequisitos_faltantes": b["prereq_faltantes"],
                }
                for b in bloqueados
            ],
        }
    )


@mcp.tool()
def obtener_malla_curricular(
    codigo_programa: str = "ING-SIS",
    semestre: int | None = None,
) -> str:
    """Devuelve la malla curricular de un programa con sus prerrequisitos.

    Args:
        codigo_programa: Código del programa (por defecto "ING-SIS").
        semestre: Filtra por semestre sugerido (1-12). Opcional.
    """
    rows = fetch_all(
        """
        SELECT semestre_sugerido, codigo_curso, curso, creditos,
               tipo, area, prerrequisitos
        FROM unab.v_malla_curricular
        WHERE codigo_programa = %s
          AND (%s IS NULL OR semestre_sugerido = %s)
        ORDER BY semestre_sugerido, codigo_curso
        """,
        (codigo_programa.strip().upper(), semestre, semestre),
    )
    if not rows:
        return no_encontrado(
            "No se encontró la malla para ese programa o semestre.",
            codigo_programa=codigo_programa,
        )
    return ok(
        codigo_programa=codigo_programa.strip().upper(),
        total=len(rows),
        malla=rows,
    )
