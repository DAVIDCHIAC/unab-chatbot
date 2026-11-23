#!/usr/bin/env python3
"""Actualiza la URL del servidor MCP en los workflows de `n8n/`.

Los workflows se importan con una URL de ejemplo; cuando el túnel de
Cloudflare cambia de hostname (o pasas a un dominio fijo con Caddy), este
script reescribe los tres nodos MCP Client de los JSON del repositorio.

Uso:
    python actualizar_mcp.py https://mi-tunel.trycloudflare.com/mcp
    python actualizar_mcp.py https://54-211-28-77.sslip.io/mcp
    python actualizar_mcp.py --ver          # solo muestra la URL actual

Después de ejecutarlo, vuelve a importar los workflows en n8n (o cambia el
campo `Endpoint URL` del nodo *MCP Client* en la interfaz).
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
ARCHIVOS = [
    "wf01_rag_institucional.json",
    "wf02_calendario.json",
    "wf03_historial_mcp.json",
]
CLAVE = "endpointUrl"


def _recorrer(nodos: list[dict], url: str) -> int:
    cambios = 0
    for nodo in nodos:
        parametros = nodo.get("parameters") or {}
        if CLAVE in parametros and parametros[CLAVE] != url:
            parametros[CLAVE] = url
            cambios += 1
    return cambios


def main() -> int:
    parser = argparse.ArgumentParser(description="Cambia la URL del MCP en n8n/*.json")
    parser.add_argument("url", nargs="?", help="Nueva URL del endpoint MCP")
    parser.add_argument("--ver", action="store_true", help="Solo mostrar la URL actual")
    args = parser.parse_args()

    if args.ver or not args.url:
        for nombre in ARCHIVOS:
            ruta = BASE / nombre
            if not ruta.exists():
                print(f"  ! falta {nombre}")
                continue
            datos = json.loads(ruta.read_text(encoding="utf-8"))
            for nodo in datos.get("nodes", []):
                url = (nodo.get("parameters") or {}).get(CLAVE)
                if url:
                    print(f"{nombre}: {url}")
        return 0

    url = args.url.strip()
    if not url.startswith("https://") or not url.rstrip("/").endswith("/mcp"):
        print("La URL debe empezar por https:// y terminar en /mcp", file=sys.stderr)
        return 2

    total = 0
    for nombre in ARCHIVOS:
        ruta = BASE / nombre
        if not ruta.exists():
            print(f"  ! falta {nombre}")
            continue
        datos = json.loads(ruta.read_text(encoding="utf-8"))
        cambios = _recorrer(datos.get("nodes", []), url)
        if cambios:
            ruta.write_text(
                json.dumps(datos, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
        print(f"{nombre}: {cambios} nodo(s) actualizado(s)")
        total += cambios

    print(f"\nTotal: {total} nodos -> {url}")
    if total == 0:
        print("(ya estaban en esa URL)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
