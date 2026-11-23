"""Instancia única de FastMCP con la configuración de transporte."""

from __future__ import annotations

from mcp.server.fastmcp import FastMCP
from mcp.server.transport_security import TransportSecuritySettings

from .config import settings

mcp = FastMCP(
    settings.app_name,
    instructions=(
        "Servidor MCP del Chatbot de Apoyo Académico de la UNAB. "
        "Expone herramientas de solo lectura sobre el historial académico, "
        "el pensum, el calendario, las noticias y la base de conocimiento RAG. "
        "Usa 'identificar_estudiante' antes de consultar datos personales y "
        "responde siempre en español."
    ),
    host=settings.mcp_host,
    port=settings.mcp_port,
    streamable_http_path=settings.mcp_path,
    stateless_http=True,
    json_response=False,
    transport_security=TransportSecuritySettings(
        enable_dns_rebinding_protection=settings.mcp_dns_protection,
        allowed_hosts=settings.mcp_allowed_hosts,
        allowed_origins=settings.mcp_allowed_origins,
    ),
)
