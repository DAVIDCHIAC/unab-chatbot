"""Configuración central del servidor MCP (leída de variables de entorno)."""

from __future__ import annotations

import os
from dataclasses import dataclass, field

from dotenv import load_dotenv

load_dotenv()


def _str(name: str, default: str = "") -> str:
    return (os.getenv(name) or default).strip()


def _int(name: str, default: int) -> int:
    try:
        return int(os.getenv(name, default))
    except (TypeError, ValueError):
        return default


def _float(name: str, default: float) -> float:
    try:
        return float(os.getenv(name, default))
    except (TypeError, ValueError):
        return default


def _list(name: str, default: str = "") -> list[str]:
    raw = _str(name, default)
    return [item.strip() for item in raw.split(",") if item.strip()]


@dataclass(frozen=True)
class Settings:
    # --- Aplicación ---------------------------------------------------------
    app_name: str = _str("APP_NAME", "UNAB Academic MCP")
    app_env: str = _str("APP_ENV", "development")
    log_level: str = _str("LOG_LEVEL", "INFO").upper()

    # --- PostgreSQL / Supabase ---------------------------------------------
    db_host: str = _str("DB_HOST")
    db_port: int = _int("DB_PORT", 5432)
    db_name: str = _str("DB_NAME", "postgres")
    db_user: str = _str("DB_USER", "postgres")
    db_password: str = _str("DB_PASSWORD")
    db_sslmode: str = _str("DB_SSLMODE", "require")
    db_pool_min: int = _int("DB_POOL_MIN", 1)
    db_pool_max: int = _int("DB_POOL_MAX", 10)
    db_connect_timeout: int = _int("DB_CONNECT_TIMEOUT", 10)

    # --- Servidor MCP -------------------------------------------------------
    mcp_host: str = _str("MCP_HOST", "0.0.0.0")
    mcp_port: int = _int("MCP_PORT", 9000)
    mcp_path: str = _str("MCP_PATH", "/mcp")
    mcp_api_token: str = _str("MCP_API_TOKEN")
    mcp_dns_protection: bool = _str("MCP_DNS_PROTECTION", "true").lower() in {
        "1",
        "true",
        "yes",
        "on",
    }
    mcp_allowed_hosts: list[str] = field(
        default_factory=lambda: _list(
            "MCP_ALLOWED_HOSTS",
            "localhost:*,127.0.0.1:*,0.0.0.0:*",
        )
    )
    mcp_allowed_origins: list[str] = field(
        default_factory=lambda: _list("MCP_ALLOWED_ORIGINS", "")
    )

    # --- Embeddings (RAG) ---------------------------------------------------
    # EMBEDDING_PROVIDER: "openai" | "gemini" | "cohere" | vacío (autodetecta).
    embedding_provider: str = _str("EMBEDDING_PROVIDER").lower()
    openai_api_key: str = _str("OPENAI_API_KEY")
    openai_base_url: str = _str("OPENAI_BASE_URL", "https://api.openai.com/v1")
    embedding_model: str = _str("EMBEDDING_MODEL", "text-embedding-3-small")
    embedding_dim: int = _int("EMBEDDING_DIM", 1536)
    embedding_timeout: float = _float("EMBEDDING_TIMEOUT", 30.0)

    # Gemini (Google AI Studio) — alternativa gratuita a OpenAI.
    gemini_api_key: str = _str("GEMINI_API_KEY") or _str("GOOGLE_API_KEY")
    gemini_base_url: str = _str(
        "GEMINI_BASE_URL", "https://generativelanguage.googleapis.com/v1beta"
    )
    gemini_embedding_model: str = _str(
        "GEMINI_EMBEDDING_MODEL", "gemini-embedding-001"
    )

    # Cohere — trial key gratuita, embed-v4.0 con 1536 dimensiones.
    cohere_api_key: str = _str("COHERE_API_KEY")
    cohere_base_url: str = _str("COHERE_BASE_URL", "https://api.cohere.com/v2")
    cohere_embedding_model: str = _str("COHERE_EMBEDDING_MODEL", "embed-v4.0")

    @property
    def is_production(self) -> bool:
        return self.app_env.lower() in {"prod", "production"}

    @property
    def resolved_embedding_provider(self) -> str:
        """Proveedor de embeddings efectivo ("" si falta la clave)."""
        if self.embedding_provider == "openai":
            return "openai" if self.openai_api_key else ""
        if self.embedding_provider == "gemini":
            return "gemini" if self.gemini_api_key else ""
        if self.embedding_provider == "cohere":
            return "cohere" if self.cohere_api_key else ""
        if self.openai_api_key:
            return "openai"
        if self.gemini_api_key:
            return "gemini"
        if self.cohere_api_key:
            return "cohere"
        return ""


settings = Settings()
