"""Registro de todas las herramientas MCP.

Importar este paquete es suficiente para que FastMCP descubra las tools
decoradas con @mcp.tool().
"""

from . import academico, calendario, estudiantes, noticias, rag, soporte  # noqa: F401

__all__ = [
    "academico",
    "calendario",
    "estudiantes",
    "noticias",
    "rag",
    "soporte",
]
