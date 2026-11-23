"""Capa de acceso a PostgreSQL / Supabase."""

from __future__ import annotations

import logging
import time
from contextlib import contextmanager
from typing import Any, Iterator, Sequence

import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor

from .config import settings

logger = logging.getLogger(__name__)

_pool: pool.ThreadedConnectionPool | None = None


def init_pool(retries: int = 5, delay: float = 3.0) -> None:
    """Crea el pool de conexiones con reintentos (útil al arrancar en Docker)."""
    global _pool
    if _pool is not None:
        return

    last_error: Exception | None = None
    for attempt in range(1, retries + 1):
        try:
            _pool = pool.ThreadedConnectionPool(
                minconn=settings.db_pool_min,
                maxconn=settings.db_pool_max,
                host=settings.db_host,
                port=settings.db_port,
                dbname=settings.db_name,
                user=settings.db_user,
                password=settings.db_password,
                sslmode=settings.db_sslmode,
                connect_timeout=settings.db_connect_timeout,
                application_name="unab-mcp",
            )
            logger.info(
                "Pool PostgreSQL listo (%s:%s/%s, sslmode=%s)",
                settings.db_host,
                settings.db_port,
                settings.db_name,
                settings.db_sslmode,
            )
            return
        except Exception as exc:  # pragma: no cover - depende del entorno
            last_error = exc
            logger.warning(
                "No se pudo conectar a PostgreSQL (intento %s/%s): %s",
                attempt,
                retries,
                exc,
            )
            time.sleep(delay)

    raise RuntimeError(f"No se pudo inicializar el pool de PostgreSQL: {last_error}")


def close_pool() -> None:
    global _pool
    if _pool is not None:
        _pool.closeall()
        _pool = None
        logger.info("Pool PostgreSQL cerrado")


def _get_pool() -> pool.ThreadedConnectionPool:
    if _pool is None:
        init_pool()
    assert _pool is not None, "Pool no inicializado"
    return _pool


@contextmanager
def cursor(commit: bool = False) -> Iterator[RealDictCursor]:
    """Entrega un cursor con manejo automático de commit/rollback."""
    conn = _get_pool().getconn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            yield cur
        if commit:
            conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        _get_pool().putconn(conn)


def fetch_all(sql: str, params: Sequence[Any] | None = None) -> list[dict[str, Any]]:
    with cursor() as cur:
        cur.execute(sql, params or ())
        return [dict(row) for row in cur.fetchall()]


def fetch_one(sql: str, params: Sequence[Any] | None = None) -> dict[str, Any] | None:
    with cursor() as cur:
        cur.execute(sql, params or ())
        row = cur.fetchone()
        return dict(row) if row else None


def execute(sql: str, params: Sequence[Any] | None = None) -> dict[str, Any]:
    """Ejecuta una sentencia de escritura y devuelve el RETURNING (si existe)."""
    with cursor(commit=True) as cur:
        cur.execute(sql, params or ())
        if cur.description:
            row = cur.fetchone()
            return dict(row) if row else {}
        return {"filas_afectadas": cur.rowcount}


def ping() -> bool:
    try:
        return fetch_one("SELECT 1 AS ok") is not None
    except Exception:
        return False
