"""Cliente de prueba para el servidor MCP (Streamable HTTP).

Uso:
    python test_client.py --url http://127.0.0.1:9000/mcp
    python test_client.py --url https://midominio.duckdns.org/mcp --token TU_TOKEN
"""

from __future__ import annotations

import argparse
import asyncio
import os
import sys

from mcp import ClientSession
from mcp.client.streamable_http import streamablehttp_client

# En Windows la consola suele usar cp1252 y rompe los acentos.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

PRUEBAS: list[tuple[str, dict]] = [
    ("ping", {}),
    ("listar_programas", {}),
    ("identificar_estudiante", {"identificador": "10045234"}),
    ("obtener_estado_academico", {"id_estudiante": "10045234"}),
    ("obtener_historial", {"id_estudiante": "10045234", "solo_reprobados": True}),
    ("obtener_cursos_pendientes", {"id_estudiante": "10045234", "limite": 5}),
    ("obtener_prerrequisitos_pendientes", {"id_estudiante": "10045234"}),
    ("proyectar_semestres", {"id_estudiante": "10045231"}),
    ("recomendar_matricula", {"id_estudiante": "10045234", "max_creditos": 18}),
    ("obtener_malla_curricular", {"codigo_programa": "ING-SIS", "semestre": 3}),
    ("consultar_calendario", {"texto": "matrícula", "limite": 3}),
    ("obtener_periodo_activo", {}),
    ("consultar_noticias", {"limite": 2}),
    ("buscar_conocimiento_institucional", {"consulta": "competencias digitales", "limite": 2}),
    ("estadisticas_conocimiento", {}),
    (
        "registrar_conversacion",
        {
            "session_id": "sesion-demo-001",
            "pregunta": "¿Cuántos créditos me faltan?",
            "respuesta": "Según tu historial, te faltan 130 créditos.",
            "tipo": "academico",
            "id_estudiante": "10045234",
            "fuentes": ["v_avance_plan"],
            "latencia_ms": 850,
        },
    ),
    (
        "crear_solicitud",
        {
            "tipo_solicitud": "revisión de nota",
            "descripcion": "Solicito revisar la nota del segundo corte de Cálculo Integral.",
            "id_estudiante": "10045234",
            "nombre_estudiante": "Jhon García",
            "prioridad": "alta",
        },
    ),
    ("consultar_solicitudes", {"id_estudiante": "10045234"}),
]


async def ejecutar(url: str, token: str) -> None:
    headers = {"Authorization": f"Bearer {token}"} if token else None

    async with streamablehttp_client(url, headers=headers) as (read, write, _):
        async with ClientSession(read, write) as session:
            await session.initialize()

            listado = await session.list_tools()
            print(f"\nHerramientas disponibles ({len(listado.tools)}):")
            for tool in listado.tools:
                primera_linea = (tool.description or "").splitlines()[0]
                print(f"  - {tool.name}: {primera_linea[:90]}")

            for nombre, argumentos in PRUEBAS:
                print(f"\n=== {nombre} ===")
                try:
                    resultado = await session.call_tool(nombre, argumentos)
                    texto = "".join(
                        bloque.text
                        for bloque in resultado.content
                        if getattr(bloque, "text", None)
                    )
                    print(texto[:1000])
                except Exception as exc:  # pragma: no cover
                    print(f"ERROR: {exc}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Prueba del servidor MCP UNAB")
    parser.add_argument(
        "--url",
        default=os.getenv("MCP_URL", "http://127.0.0.1:9000/mcp"),
        help="URL del endpoint MCP",
    )
    parser.add_argument(
        "--token",
        default=os.getenv("MCP_API_TOKEN", ""),
        help="Bearer token (si el servidor lo exige)",
    )
    args = parser.parse_args()
    asyncio.run(ejecutar(args.url, args.token))


if __name__ == "__main__":
    main()
