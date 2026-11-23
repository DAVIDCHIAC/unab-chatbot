"""Herramientas de registro: conversaciones, solicitudes y diagnóstico."""

from __future__ import annotations

import json

from ..core import mcp
from ..db import execute, fetch_all, fetch_one, ping as db_ping
from ..utils import limitar, ok, to_json


@mcp.tool()
def registrar_conversacion(
    session_id: str,
    pregunta: str,
    respuesta: str,
    tipo: str = "consulta",
    id_estudiante: str | None = None,
    fuentes: list[str] | None = None,
    latencia_ms: int = 0,
) -> str:
    """Guarda una interacción en el historial para auditoría y métricas.

    Args:
        session_id: Identificador de la sesión o del chat.
        pregunta: Texto de la pregunta del estudiante.
        respuesta: Texto de la respuesta generada.
        tipo: Tipo de consulta (rag, academico, calendario, noticias, menu).
        id_estudiante: Código UNAB del estudiante, si se conoce. Opcional.
        fuentes: Lista de documentos o vistas usadas como fuente. Opcional.
        latencia_ms: Tiempo de respuesta en milisegundos.
    """
    if not session_id or not pregunta:
        return to_json(
            {"status": "error", "mensaje": "session_id y pregunta son obligatorios."}
        )

    fila = execute(
        """
        INSERT INTO unab.conversaciones
            (session_id, canal, id_estudiante, pregunta, respuesta, tipo,
             fuentes, latencia_ms)
        VALUES (%s, 'mcp', %s, %s, %s, %s, %s::jsonb, %s)
        RETURNING id, created_at
        """,
        (
            session_id.strip(),
            (id_estudiante or "").strip() or None,
            pregunta,
            respuesta,
            tipo,
            json.dumps(fuentes or [], ensure_ascii=False),
            max(0, int(latencia_ms)),
        ),
    )
    return ok(conversacion=fila)


@mcp.tool()
def crear_solicitud(
    tipo_solicitud: str,
    descripcion: str,
    id_estudiante: str | None = None,
    nombre_estudiante: str | None = None,
    prioridad: str = "media",
) -> str:
    """Crea un caso de soporte para Bienestar o Registro Académico.

    Args:
        tipo_solicitud: Categoría del caso (ej. "revisión de nota",
            "cancelación de asignatura", "cita con consejería").
        descripcion: Detalle de la solicitud del estudiante.
        id_estudiante: Código UNAB. Opcional.
        nombre_estudiante: Nombre completo. Opcional.
        prioridad: baja, media o alta.
    """
    if not tipo_solicitud or not descripcion:
        return to_json(
            {
                "status": "error",
                "mensaje": "tipo_solicitud y descripcion son obligatorios.",
            }
        )

    prioridad = prioridad if prioridad in {"baja", "media", "alta"} else "media"

    fila = execute(
        """
        INSERT INTO unab.solicitudes
            (id_estudiante, nombre_estudiante, tipo_solicitud, descripcion,
             estado, prioridad, enviado_sheets)
        VALUES (%s, %s, %s, %s, 'pendiente', %s, FALSE)
        RETURNING id, created_at, estado, prioridad
        """,
        (
            (id_estudiante or "").strip() or None,
            (nombre_estudiante or "").strip() or None,
            tipo_solicitud.strip(),
            descripcion.strip(),
            prioridad,
        ),
    )
    return ok(solicitud=fila)


@mcp.tool()
def consultar_solicitudes(id_estudiante: str, limite: int = 10) -> str:
    """Lista las solicitudes de soporte registradas por un estudiante.

    Args:
        id_estudiante: Código UNAB del estudiante.
        limite: Número máximo de solicitudes (1-50).
    """
    id_estudiante = (id_estudiante or "").strip()
    if not id_estudiante:
        return to_json({"status": "error", "mensaje": "Falta el código."})

    limite = limitar(limite, 1, 50)
    filas = fetch_all(
        """
        SELECT id, tipo_solicitud, descripcion, estado, prioridad,
               asignado_a, created_at, updated_at
        FROM unab.solicitudes
        WHERE id_estudiante = %s
        ORDER BY created_at DESC
        LIMIT %s
        """,
        (id_estudiante, limite),
    )
    return ok(id_estudiante=id_estudiante, total=len(filas), solicitudes=filas)


@mcp.tool()
def ping() -> str:
    """Verifica el estado del servidor MCP y de la conexión a Supabase."""
    db_ok = db_ping()
    resumen = None
    if db_ok:
        resumen = fetch_one(
            """
            SELECT
                (SELECT COUNT(*) FROM unab.estudiantes)            AS estudiantes,
                (SELECT COUNT(*) FROM unab.cursos)                 AS cursos,
                (SELECT COUNT(*) FROM unab.conversaciones)         AS conversaciones,
                (SELECT COUNT(*) FROM unab.documentos_vectoriales) AS chunks_rag
            """
        )
    return to_json(
        {
            "status": "ok" if db_ok else "degradado",
            "servidor": "unab-mcp",
            "base_de_datos": "ok" if db_ok else "error",
            "resumen": resumen,
        }
    )
