"""Generación de embeddings (OpenAI, Google Gemini o Cohere).

El proveedor se elige con ``EMBEDDING_PROVIDER`` o, si está vacío, se
autodetecta por la clave disponible: ``OPENAI_API_KEY`` → ``GEMINI_API_KEY``
→ ``COHERE_API_KEY``.

Los tres se normalizan a la misma dimensión (``EMBEDDING_DIM``, 1536 por
defecto) para que la columna ``vector(1536)`` sirva sin cambios.
"""

from __future__ import annotations

import logging

import httpx

from .config import settings

logger = logging.getLogger(__name__)

# Límite de caracteres por fragmento que se envía al proveedor.
MAX_CHARS = 8000


class EmbeddingError(RuntimeError):
    """Error controlado al generar un embedding."""


def provider() -> str:
    """Proveedor efectivo: ``openai``, ``gemini`` o cadena vacía."""
    return settings.resolved_embedding_provider


def disponible() -> bool:
    return bool(provider())


def _post(url: str, *, headers: dict[str, str], payload: dict) -> dict:
    try:
        with httpx.Client(timeout=settings.embedding_timeout) as client:
            response = client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            return response.json()
    except httpx.HTTPStatusError as exc:
        raise EmbeddingError(
            f"{provider()} respondió {exc.response.status_code}: "
            f"{exc.response.text[:200]}"
        ) from exc
    except Exception as exc:  # pragma: no cover - red
        raise EmbeddingError(f"No se pudo generar el embedding: {exc}") from exc


def _embeddings_openai(textos: list[str]) -> list[list[float]]:
    payload: dict = {"model": settings.embedding_model, "input": textos}
    if settings.embedding_model.startswith("text-embedding-3"):
        payload["dimensions"] = settings.embedding_dim

    data = _post(
        f"{settings.openai_base_url}/embeddings",
        headers={"Authorization": f"Bearer {settings.openai_api_key}"},
        payload=payload,
    )
    return [item.get("embedding", []) for item in data.get("data", [])]


def _embeddings_gemini(textos: list[str], *, tipo: str) -> list[list[float]]:
    modelo = settings.gemini_embedding_model
    tarea = "RETRIEVAL_DOCUMENT" if tipo == "documento" else "RETRIEVAL_QUERY"

    peticiones = [
        {
            "model": f"models/{modelo}",
            "content": {"parts": [{"text": texto}]},
            "taskType": tarea,
        }
        for texto in textos
    ]
    # gemini-embedding-001 admite dimensiones de salida configurables (MRL).
    if modelo.startswith("gemini-embedding"):
        for peticion in peticiones:
            peticion["outputDimensionality"] = settings.embedding_dim

    data = _post(
        f"{settings.gemini_base_url}/models/{modelo}:batchEmbedContents",
        headers={
            "x-goog-api-key": settings.gemini_api_key,
            "Content-Type": "application/json",
        },
        payload={"requests": peticiones},
    )
    return [item.get("values", []) for item in data.get("embeddings", [])]


def _embeddings_cohere(textos: list[str], *, tipo: str) -> list[list[float]]:
    """Cohere embed-v4.0 (trial gratuito). Máximo 96 textos por petición."""
    modelo = settings.cohere_embedding_model
    entrada = "search_document" if tipo == "documento" else "search_query"
    salida: list[list[float]] = []

    for inicio in range(0, len(textos), 96):
        lote = textos[inicio : inicio + 96]
        data = _post(
            f"{settings.cohere_base_url}/embed",
            headers={
                "Authorization": f"Bearer {settings.cohere_api_key}",
                "Content-Type": "application/json",
            },
            payload={
                "model": modelo,
                "texts": lote,
                "input_type": entrada,
                "embedding_types": ["float"],
                "output_dimension": settings.embedding_dim,
            },
        )
        salida.extend(data.get("embeddings", {}).get("float", []))

    return salida


def embed_many(textos: list[str], *, tipo: str = "documento") -> list[list[float]]:
    """Genera embeddings para varios textos (``tipo``: documento o consulta)."""
    limpios = [(texto or "").strip()[:MAX_CHARS] for texto in textos]
    if not limpios:
        return []
    if any(not texto for texto in limpios):
        raise EmbeddingError("Hay textos vacíos para embedding")

    actual = provider()
    if not actual:
        raise EmbeddingError(
            "No hay proveedor de embeddings configurado "
            "(define OPENAI_API_KEY, GEMINI_API_KEY o COHERE_API_KEY)"
        )

    if actual == "openai":
        vectores = _embeddings_openai(limpios)
    elif actual == "cohere":
        vectores = _embeddings_cohere(limpios, tipo=tipo)
    else:
        vectores = _embeddings_gemini(limpios, tipo=tipo)

    if len(vectores) != len(limpios):
        raise EmbeddingError(
            f"{actual} devolvió {len(vectores)} embeddings para {len(limpios)} textos"
        )
    for vector in vectores:
        if len(vector) != settings.embedding_dim:
            raise EmbeddingError(
                "El embedding recibido no tiene la dimensión esperada "
                f"({settings.embedding_dim}, llegó {len(vector)})"
            )
    return vectores


def embed(texto: str, *, tipo: str = "consulta") -> list[float]:
    """Genera el embedding de un único texto."""
    return embed_many([texto], tipo=tipo)[0]


def to_pgvector(vector: list[float]) -> str:
    """Convierte una lista de floats al formato textual de pgvector."""
    return "[" + ",".join(f"{valor:.8f}" for valor in vector) + "]"
