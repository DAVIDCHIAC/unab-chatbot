"""Punto de entrada del servidor MCP de apoyo académico UNAB.

Transporte: Streamable HTTP en http://<host>:9000/mcp
"""

from __future__ import annotations

import logging

import uvicorn
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse, Response

from app import tools  # noqa: F401  (registra las herramientas)
from app.config import settings
from app.core import mcp
from app.db import close_pool, init_pool, ping

logging.basicConfig(
    level=settings.log_level,
    format="%(asctime)s | %(levelname)-7s | %(name)s | %(message)s",
)
logger = logging.getLogger("unab-mcp")

#lista original de herramientas, se sustituye en main()
_LISTA_TOOLS_ORIGINAL = None


class BearerAuthMiddleware(BaseHTTPMiddleware):
    """Autenticación opcional por Bearer token.

    Se activa únicamente si MCP_API_TOKEN tiene valor.

    Compatibilidades necesarias en el despliegue real:
    * n8n Cloud puede enviar el token con el prefijo ``Bearer `` duplicado;
      se normaliza antes de comparar.
    * El nodo MCP Client de n8n Cloud no reenvía la credencial Bearer en
      algunas versiones. Solo para el hostname del túnel público
      (``*.trycloudflare.com``) se aceptan peticiones sin Authorization.
      El acceso directo por IP sigue exigiendo el token.
    """

    async def dispatch(self, request: Request, call_next):
        if settings.mcp_api_token and request.url.path != "/health":
            recibido = request.headers.get("authorization", "").strip()
            while recibido.lower().startswith("bearer "):
                recibido = recibido[7:].strip()
            esperado = settings.mcp_api_token.strip()

            host = request.headers.get("host", "").split(":")[0].lower()
            if not recibido and host.endswith(".trycloudflare.com"):
                return await call_next(request)

            if recibido != esperado:
                logger.warning(
                    "Petición rechazada (token inválido) en %s", request.url.path
                )
                return JSONResponse({"error": "unauthorized"}, status_code=401)
        return await call_next(request)


def _sanitize_schema(schema):
    """Convierte esquemas con anyOf/type-list en esquemas planos.

    n8n transforma ``anyOf: [{type: string}, {type: null}]`` en
    ``type: ["string", "null"]``, y la API de Gemini rechaza ese array en las
    declaraciones de funciones de los tool calls. Además, un ``default: null``
    induce a Gemini a enviar ``null`` en un field declarado como string, lo que
    provoca ``ToolInputParsingException`` en n8n.
    """
    if isinstance(schema, list):
        return [_sanitize_schema(x) for x in schema]
    if not isinstance(schema, dict):
        return schema

    for clave in ("anyOf", "oneOf"):
        opciones = schema.get(clave)
        if isinstance(opciones, list) and opciones:
            validas = [
                o for o in opciones
                if isinstance(o, dict) and o.get("type") != "null"
            ]
            if validas:
                base = _sanitize_schema(validas[0])
                for hermano, valor in schema.items():
                    if hermano != clave and hermano not in base:
                        base[hermano] = _sanitize_schema(valor)
                if base.get("default", 0) is None:
                    base.pop("default", None)
                return base

    salida = {}
    for clave, valor in schema.items():
        if clave == "type" and isinstance(valor, list):
            no_null = [t for t in valor if t != "null"]
            salida[clave] = no_null[0] if no_null else valor[0]
        else:
            salida[clave] = _sanitize_schema(valor)
    if salida.get("default", 0) is None:
        salida.pop("default", None)
    return salida


def _list_tools_sanitizado():
    """Devuelve las herramientas con esquemas compatibles con n8n/Gemini."""
    herramientas = _LISTA_TOOLS_ORIGINAL()
    for herramienta in herramientas:
        herramienta.parameters = _sanitize_schema(herramienta.parameters)
    return herramientas


@mcp.custom_route("/health", methods=["GET"])
async def health(_request: Request) -> Response:
    """Endpoint de salud para Docker / balanceadores."""
    db_ok = ping()
    return JSONResponse(
        {
            "status": "ok",
            "service": settings.app_name,
            "env": settings.app_env,
            "database": "ok" if db_ok else "error",
        },
        status_code=200 if db_ok else 503,
    )


def main() -> None:
    global _LISTA_TOOLS_ORIGINAL

    _LISTA_TOOLS_ORIGINAL = mcp._tool_manager.list_tools
    mcp._tool_manager.list_tools = _list_tools_sanitizado
    logger.info("Esquemas MCP normalizados para herramientas de n8n/Gemini")

    init_pool()
    try:
        app = mcp.streamable_http_app()
        if settings.mcp_api_token:
            app.add_middleware(BearerAuthMiddleware)
            logger.info("Autenticación por Bearer token activada (túnel permitido)")

        logger.info(
            "MCP escuchando en http://%s:%s%s",
            settings.mcp_host,
            settings.mcp_port,
            settings.mcp_path,
        )
        uvicorn.run(
            app,
            host=settings.mcp_host,
            port=settings.mcp_port,
            log_level=settings.log_level.lower(),
            access_log=False,
        )
    finally:
        close_pool()


if __name__ == "__main__":
    main()
