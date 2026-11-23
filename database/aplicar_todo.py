#!/usr/bin/env python3
"""
Aplica en orden los scripts SQL del Módulo 1 (base de datos UNAB).

Uso
---
    python database/aplicar_todo.py "postgresql://postgres:PASSWORD@HOST:5432/postgres"

La cadena de conexión también se puede pasar por variable de entorno
(`UNAB_DB_URL`, `SUPABASE_DB_URL` o `DATABASE_URL`).

Opciones
--------
    --only 01,02,03   Ejecuta solo esos scripts.
    --skip 05,06      Omite esos scripts.
    --list            Muestra los scripts y no ejecuta nada.
    --yes             No pide confirmación.
    --timeout 600     Timeout por script en segundos (0 = sin límite).

Notas
-----
* Cada archivo se ejecuta en su propia transacción: si uno falla, se revierte
  solo ese archivo y el proceso se detiene.
* `05_rls_policies.sql` usa `auth.uid()` y solo funciona en Supabase. Si el
  servidor no tiene el esquema `auth`, el script lo omite automáticamente.
* Todos los archivos son idempotentes, así que se puede volver a ejecutar.
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import time
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
PATRON = re.compile(r"^(\d{2})_.*\.sql$", re.IGNORECASE)

VERIFICACION = """
SELECT 'programas' AS tabla, COUNT(*) AS filas FROM unab.programas
UNION ALL SELECT 'cursos', COUNT(*) FROM unab.cursos
UNION ALL SELECT 'prerrequisitos', COUNT(*) FROM unab.prerrequisitos
UNION ALL SELECT 'estudiantes', COUNT(*) FROM unab.estudiantes
UNION ALL SELECT 'historial', COUNT(*) FROM unab.historial_academico
UNION ALL SELECT 'calendario', COUNT(*) FROM unab.calendario_academico
UNION ALL SELECT 'noticias', COUNT(*) FROM unab.noticias
UNION ALL SELECT 'documentos', COUNT(*) FROM unab.documentos
UNION ALL SELECT 'chunks_rag', COUNT(*) FROM unab.documentos_vectoriales
UNION ALL SELECT 'vistas', (
    SELECT COUNT(*) FROM pg_views WHERE schemaname = 'unab'
)
ORDER BY tabla;
"""


def scripts_disponibles() -> list[Path]:
    archivos = []
    for ruta in sorted(BASE_DIR.glob("*.sql")):
        if PATRON.match(ruta.name):
            archivos.append(ruta)
    return archivos


def numero(ruta: Path) -> str:
    return ruta.name[:2]


def cadena_conexion(valor: str | None) -> str:
    if valor:
        return valor
    for nombre in ("UNAB_DB_URL", "SUPABASE_DB_URL", "DATABASE_URL"):
        candidato = os.environ.get(nombre)
        if candidato:
            return candidato
    raise SystemExit(
        "Falta la cadena de conexión.\n"
        "Pásala como argumento o en UNAB_DB_URL:\n"
        '  python database/aplicar_todo.py "postgresql://postgres:...@host:5432/postgres"'
    )


def ocultar(url: str) -> str:
    return re.sub(r"(://[^:/@]+:)[^@]*@", r"\1****@", url)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Aplica los scripts SQL del Módulo 1 en orden."
    )
    parser.add_argument("url", nargs="?", help="Cadena de conexión PostgreSQL")
    parser.add_argument("--only", help="Números separados por coma (ej. 01,02)")
    parser.add_argument("--skip", help="Números separados por coma a omitir")
    parser.add_argument("--list", action="store_true", help="Solo listar")
    parser.add_argument("--yes", "-y", action="store_true", help="Sin confirmación")
    parser.add_argument(
        "--timeout", type=int, default=600, help="Timeout por script en segundos"
    )
    args = parser.parse_args()

    archivos = scripts_disponibles()
    if not archivos:
        print("No se encontraron scripts 01..NN en", BASE_DIR)
        return 1

    if args.only:
        permitidos = {n.strip().zfill(2) for n in args.only.split(",") if n.strip()}
        archivos = [a for a in archivos if numero(a) in permitidos]
    if args.skip:
        omitidos = {n.strip().zfill(2) for n in args.skip.split(",") if n.strip()}
        archivos = [a for a in archivos if numero(a) not in omitidos]

    if args.list:
        for ruta in archivos:
            print(f"  {numero(ruta)}  {ruta.name}  ({ruta.stat().st_size} bytes)")
        return 0

    try:
        import psycopg2  # noqa: F401
    except ImportError:
        print(
            "Falta psycopg2. Instálalo con:\n"
            "  python -m pip install psycopg2-binary"
        )
        return 1

    import psycopg2

    url = cadena_conexion(args.url)
    print("Destino:", ocultar(url))
    print("Scripts:")
    for ruta in archivos:
        print(f"  - {ruta.name}")
    if not args.yes:
        respuesta = input("¿Continuar? [s/N] ").strip().lower()
        if respuesta not in ("s", "si", "sí", "y", "yes"):
            print("Cancelado.")
            return 1

    opciones = f"-c statement_timeout={args.timeout * 1000}" if args.timeout else ""
    conn = psycopg2.connect(url, options=opciones or None)
    conn.autocommit = False

    try:
        with conn.cursor() as cur:
            cur.execute("SELECT current_database(), current_user, version()")
            base, usuario, version = cur.fetchone()
            print(f"\nConectado a «{base}» como «{usuario}»")
            print(version.split(",")[0])
            cur.execute("SELECT 1 FROM pg_namespace WHERE nspname = 'auth'")
            es_supabase = cur.fetchone() is not None
        conn.commit()
    except Exception:
        conn.close()
        raise

    print("Supabase detectado:", "sí" if es_supabase else "no (PostgreSQL puro)")

    for ruta in archivos:
        if numero(ruta) == "05" and not es_supabase:
            print(f"\n[05] {ruta.name}: omitido (requiere el esquema auth de Supabase)")
            continue

        sql = ruta.read_text(encoding="utf-8-sig")
        print(f"\n[{numero(ruta)}] {ruta.name} …", flush=True)
        inicio = time.time()
        try:
            with conn.cursor() as cur:
                cur.execute(sql)
            conn.commit()
        except Exception as exc:  # noqa: BLE001
            conn.rollback()
            print(f"    ✗ ERROR: {exc}")
            print("    Se revirtió este archivo. Los anteriores quedaron aplicados.")
            return 1
        print(f"    ✓ OK ({time.time() - inicio:.1f} s)")

    print("\nVerificación de conteos:")
    try:
        with conn.cursor() as cur:
            cur.execute(VERIFICACION)
            filas = cur.fetchall()
        conn.commit()
        ancho = max(len(str(f[0])) for f in filas)
        for nombre, total in filas:
            print(f"  {str(nombre).ljust(ancho)}  {total}")
    except Exception as exc:  # noqa: BLE001
        conn.rollback()
        print(f"  (no se pudo verificar: {exc})")
    finally:
        conn.close()

    print("\nListo. Recuerda ejecutar 08_actualizar_demo.sql antes de cada demo.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
