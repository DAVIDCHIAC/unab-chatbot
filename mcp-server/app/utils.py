"""Utilidades compartidas por las herramientas MCP."""

from __future__ import annotations

import json
from typing import Any


def to_json(data: Any) -> str:
    """Serializa a JSON compacto y seguro para el LLM."""
    return json.dumps(data, ensure_ascii=False, default=str, separators=(",", ":"))


def ok(**payload: Any) -> str:
    return to_json({"status": "ok", **payload})


def error(mensaje: str, **payload: Any) -> str:
    return to_json({"status": "error", "mensaje": mensaje, **payload})


def no_encontrado(mensaje: str, **payload: Any) -> str:
    return to_json({"status": "no_encontrado", "mensaje": mensaje, **payload})


def limpiar_id(valor: str) -> str:
    return (valor or "").strip()


def limitar(valor: int, minimo: int, maximo: int) -> int:
    try:
        numero = int(valor)
    except (TypeError, ValueError):
        numero = maximo
    return max(minimo, min(numero, maximo))
