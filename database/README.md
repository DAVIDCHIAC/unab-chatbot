# Módulo 1 — Base de Datos (Supabase)

Esquema `unab` con todo lo necesario para el chatbot: datos académicos,
pensum, prerrequisitos, calendario, noticias, conversaciones y RAG con
`pgvector`.

## Archivos y orden de ejecución

Ejecuta **en este orden** en el *SQL Editor* de Supabase (o con `psql`):

| # | Archivo | Qué hace |
|---|---------|----------|
| 1 | `01_schema.sql` | Esquema `unab`, tablas, índices y triggers |
| 2 | `02_seed.sql` | Pensum de Ing. de Sistemas, 30 estudiantes, historial, calendario y noticias |
| 3 | `03_rag_pgvector.sql` | Extensión `vector`, tabla de chunks, índices HNSW y función de búsqueda |
| 4 | `04_vistas.sql` | Vistas analíticas para los agentes |
| 5 | `05_rls_policies.sql` | Seguridad a nivel de fila (Supabase Auth) |
| 6 | `06_consultas_demo.sql` | Consultas de verificación y demo (opcional) |
| 7 | `07_conocimiento_rag.sql` | Base de conocimiento institucional (23 chunks iniciales; `ingest.py` produce 27 con overlap) |
| 8 | `08_actualizar_demo.sql` | Periodo activo, calendario y noticias relativos a la fecha actual |

## Ver las tablas y los datos

- **`CONSULTAS_UTILES.sql`**: consultas listas para pegar en el *SQL Editor* de
  Supabase (tablas, cursos, estudiantes, prerrequisitos, notas, vistas, RAG y
  conversaciones).
- **`evidencias/tablas_datos_sinteticos.md`**: volcado legible y real de todas
  las tablas y vistas, con sus filas, para revisar los datos sin credenciales.

> `05_rls_policies.sql` usa `auth.uid()`, por lo que **solo funciona en Supabase**.
> Si lo corres en un PostgreSQL local, omítelo.

## Cómo ejecutarlo en Supabase

1. Entra a <https://supabase.com/dashboard> → tu proyecto → **SQL Editor**.
2. Pega y ejecuta `01_schema.sql`. Debe terminar sin errores.
3. Ejecuta `02_seed.sql`. Al final verás el conteo de registros.
4. Ejecuta `03_rag_pgvector.sql`. Verifica que la extensión `vector` esté
   habilitada en **Database → Extensions**.
5. Ejecuta `04_vistas.sql` y luego `05_rls_policies.sql`.
6. Corre `06_consultas_demo.sql` para validar (opcional).
7. Ejecuta `07_conocimiento_rag.sql` (documentos del RAG) y
   `08_actualizar_demo.sql` (calendario y noticias vigentes).

## Aplicar todo con un solo comando (recomendado)

`aplicar_todo.py` ejecuta los scripts en orden, cada uno en su propia
transacción, y al final imprime los conteos de verificación. Detecta si el
servidor es Supabase y omite `05_rls_policies.sql` cuando no existe el esquema
`auth` (PostgreSQL puro).

```bash
python -m pip install psycopg2-binary

# Cadena de conexión de Supabase → Connect → Session pooler (puerto 5432)
python database/aplicar_todo.py "postgresql://postgres.PROYECTO:PASSWORD@aws-0-region.pooler.supabase.com:5432/postgres"

# Variantes
python database/aplicar_todo.py --list                 # solo mostrar archivos
python database/aplicar_todo.py --only 07,08 --yes     # refrescar solo la demo
python database/aplicar_todo.py --skip 05,06           # omitir RLS y demo
```

También acepta la cadena en la variable de entorno `UNAB_DB_URL` (o
`SUPABASE_DB_URL` / `DATABASE_URL`), así no queda en el historial de la shell.

Antes de cada demo o grabación basta con:

```bash
python database/aplicar_todo.py --only 08 --yes
```

## Verificación rápida

```sql
-- Debe devolver 51 cursos y 30 estudiantes
SELECT 'cursos' AS tabla, COUNT(*) FROM unab.cursos
UNION ALL SELECT 'estudiantes', COUNT(*) FROM unab.estudiantes
UNION ALL SELECT 'historial', COUNT(*) FROM unab.historial_academico;

-- Estado de un estudiante de prueba
SELECT * FROM unab.v_estado_estudiante WHERE id_estudiante = '10045231';
```

## Base de conocimiento del RAG

`07_conocimiento_rag.sql` carga 23 fragmentos de seis documentos
institucionales (reglamento, FAQ académica, proceso de grado, becas y
monitorías, bienestar y CCD). Los chunks se insertan **sin embedding** para que
la búsqueda por texto funcione desde el primer momento; el servidor MCP detecta
que no hay proveedor de embeddings (Gemini, Cohere u OpenAI) y usa ese *fallback*.

Después se ejecuta `python rag/ingest.py --reindex` con
`EMBEDDING_PROVIDER=gemini`: esto añade el documento del plan de estudios, aplica
160 caracteres de *overlap* y deja **7 documentos / 27 chunks con embedding**,
todos con `metadata->>'modelo' = 'gemini:gemini-embedding-001'`.

Para activar la búsqueda vectorial, genera los embeddings con el pipeline
`rag/ingest.py` (Módulo 4) o desde el workflow WF01 de n8n. La tabla
`unab.documentos_vectoriales` ya tiene la columna `vector(1536)` y el índice
HNSW.

## Mantener la demo vigente

`08_actualizar_demo.sql` recalcula el periodo activo y regenera el calendario y
las noticias tomando `CURRENT_DATE` como referencia. Ejecútalo antes de grabar
el video o de una presentación para que el chatbot muestre siempre eventos y
noticias próximos:

```sql
-- En el SQL Editor de Supabase o con psql
\i 08_actualizar_demo.sql
```

No modifica el pensum ni el historial académico.

## Estudiantes de prueba

| Código | Nombre | Semestre | Caso de demo |
|--------|--------|----------|--------------|
| `10045234` | Jhon García | 3 | **Caso estrella:** Cálculo Integral (IS201) reprobada → Cálculo Multivariado (IS301) bloqueada y no matriculada |
| `10045231` | Laura Martínez | 9 | Avance alto (87%), cerca del grado |
| `10045232` | Carlos Rodríguez | 7 | Estudiante con una reprobación aleatoria |
| `10045235` | María Hernández | 1 | Estudiante nueva, sin historial |
| `10045236` | Luis Torres | 10 | Último semestre, 92% de avance |
| `10045260` | Simón Molina | 2 | Semestre temprano |

## Conexión desde el backend (FastMCP / n8n)

Usa la cadena de conexión de **Project Settings → Database → Connection string**.
Para el servidor MCP en AWS EC2 usa el *Session pooler* (puerto `5432`) o el
*Transaction pooler* (puerto `6543`) con `sslmode=require`.

```env
DB_HOST=aws-0-us-east-1.pooler.supabase.com
DB_PORT=6543
DB_NAME=postgres
DB_USER=postgres.<project-ref>
DB_PASSWORD=********
```

## Modelo de datos (resumen)

```
programas ──< cursos ──< prerrequisitos
    │            │
    └──< estudiantes ──< historial_academico >── cursos
              │
              ├──< conversaciones
              ├──< solicitudes
              ├──< notificaciones
              └──< dispositivos

periodos_academicos ──< calendario_academico
noticias
documentos ──> documentos_vectoriales (pgvector 1536d)
```

## Notas

- Los datos son **sintéticos**. El pensum es una aproximación; reemplázalo por
  el oficial de UNAB manteniendo las mismas columnas.
- El embedding es de **1536 dimensiones** y en producción se genera con
  `gemini-embedding-001` (registrado en `metadata->>'modelo'`). Si cambias de
  modelo, ajusta la dimensión en `03_rag_pgvector.sql` y reindexa con
  `python rag/ingest.py --reindex` para no mezclar vectores.
- La tabla `unab.documentos_vectoriales` es compatible con el nodo
  **Postgres PGVector Store** de n8n.
