-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 01_schema.sql
-- MOTOR    : PostgreSQL 15+ (Supabase)
-- ESQUEMA  : unab
-- DESCRIPCIÓN:
--   Estructura relacional base del sistema: programas, estudiantes, pensum,
--   prerrequisitos, historial académico, calendario, noticias, conversaciones,
--   solicitudes, notificaciones y dispositivos (push).
--
-- ORDEN DE EJECUCIÓN (Supabase SQL Editor):
--   01_schema.sql  ->  02_seed.sql  ->  03_rag_pgvector.sql
--   ->  04_vistas.sql  ->  05_rls_policies.sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Esquema y extensiones base
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS unab;

CREATE EXTENSION IF NOT EXISTS pgcrypto;      -- gen_random_uuid()

COMMENT ON SCHEMA unab IS 'Esquema del chatbot de apoyo académico UNAB';

-- ----------------------------------------------------------------------------
-- 1. Catálogo de programas académicos
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.programas (
    id_programa        SERIAL PRIMARY KEY,
    codigo             VARCHAR(20)  UNIQUE NOT NULL,
    nombre             VARCHAR(150) NOT NULL,
    facultad           VARCHAR(100),
    nivel              VARCHAR(20)  DEFAULT 'pregrado',
    creditos_totales   INT          DEFAULT 0,
    semestres_totales  INT          DEFAULT 10,
    activo             BOOLEAN      DEFAULT TRUE,
    created_at         TIMESTAMPTZ  DEFAULT NOW()
);

COMMENT ON TABLE unab.programas IS 'Programas académicos ofertados por la UNAB';

-- ----------------------------------------------------------------------------
-- 2. Estudiantes
--    id_estudiante = código estudiantil UNAB (ej. 10045231)
--    user_id       = vínculo opcional con Supabase Auth (auth.users.id)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.estudiantes (
    id_estudiante       VARCHAR(15) PRIMARY KEY,
    documento           VARCHAR(20) UNIQUE,
    nombre              VARCHAR(100) NOT NULL,
    apellido            VARCHAR(100) NOT NULL,
    email               VARCHAR(150) UNIQUE,
    telefono            VARCHAR(30),
    id_programa         INT REFERENCES unab.programas(id_programa),
    semestre_actual     INT DEFAULT 1,
    fecha_ingreso       DATE,
    estado              VARCHAR(20) DEFAULT 'activo',   -- activo | egresado | retirado | suspendido
    promedio_acumulado  NUMERIC(3,2) DEFAULT 0.00,
    creditos_aprobados  INT DEFAULT 0,
    user_id             UUID,                            -- auth.users(id) en Supabase
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    updated_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_estudiantes_programa ON unab.estudiantes(id_programa);
CREATE INDEX IF NOT EXISTS idx_estudiantes_user     ON unab.estudiantes(user_id);

COMMENT ON TABLE unab.estudiantes IS 'Datos generales del estudiante y su avance acumulado';

-- ----------------------------------------------------------------------------
-- 3. Pensum / plan de estudios
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.cursos (
    id_curso           SERIAL PRIMARY KEY,
    id_programa        INT NOT NULL REFERENCES unab.programas(id_programa) ON DELETE CASCADE,
    codigo_curso       VARCHAR(20) NOT NULL,
    nombre             VARCHAR(150) NOT NULL,
    creditos           INT NOT NULL DEFAULT 3,
    semestre_sugerido  INT NOT NULL DEFAULT 1,
    tipo               VARCHAR(20) DEFAULT 'obligatorio', -- obligatorio | electivo | transversal
    area               VARCHAR(80),
    horas_teoria       INT DEFAULT 0,
    horas_practica     INT DEFAULT 0,
    descripcion        TEXT,
    activo             BOOLEAN DEFAULT TRUE,
    UNIQUE (id_programa, codigo_curso)
);

CREATE INDEX IF NOT EXISTS idx_cursos_programa_semestre
    ON unab.cursos(id_programa, semestre_sugerido);

COMMENT ON TABLE unab.cursos IS 'Pensum oficial (sintético) de cada programa';

-- ----------------------------------------------------------------------------
-- 4. Prerrequisitos y correquisitos
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.prerrequisitos (
    id_curso          INT NOT NULL REFERENCES unab.cursos(id_curso) ON DELETE CASCADE,
    id_prerrequisito  INT NOT NULL REFERENCES unab.cursos(id_curso) ON DELETE CASCADE,
    tipo              VARCHAR(20) DEFAULT 'prerrequisito', -- prerrequisito | correquisito
    PRIMARY KEY (id_curso, id_prerrequisito),
    CONSTRAINT chk_no_autoprerrequisito CHECK (id_curso <> id_prerrequisito)
);

COMMENT ON TABLE unab.prerrequisitos IS 'Relación de dependencias entre asignaturas del pensum';

-- ----------------------------------------------------------------------------
-- 5. Periodos académicos
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.periodos_academicos (
    id_periodo   SERIAL PRIMARY KEY,
    codigo       VARCHAR(10) UNIQUE NOT NULL,  -- ej. 2026-1
    nombre       VARCHAR(80),
    fecha_inicio DATE,
    fecha_fin    DATE,
    activo       BOOLEAN DEFAULT FALSE
);

-- ----------------------------------------------------------------------------
-- 6. Historial académico (una fila por curso-periodo-intento)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.historial_academico (
    id               BIGSERIAL PRIMARY KEY,
    id_estudiante    VARCHAR(15) NOT NULL REFERENCES unab.estudiantes(id_estudiante) ON DELETE CASCADE,
    id_curso         INT NOT NULL REFERENCES unab.cursos(id_curso) ON DELETE CASCADE,
    periodo          VARCHAR(10) NOT NULL,          -- ej. 2024-1
    nota             NUMERIC(3,1) CHECK (nota IS NULL OR (nota >= 0 AND nota <= 5)),
    estado           VARCHAR(20) NOT NULL DEFAULT 'en_curso',
                     -- aprobado | reprobado | en_curso | cancelado | homologado
    creditos         INT DEFAULT 0,
    intento          INT DEFAULT 1,
    docente          VARCHAR(120),
    fecha_matricula  DATE,
    fecha_cierre     DATE,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (id_estudiante, id_curso, periodo)
);

CREATE INDEX IF NOT EXISTS idx_historial_estudiante ON unab.historial_academico(id_estudiante);
CREATE INDEX IF NOT EXISTS idx_historial_curso      ON unab.historial_academico(id_curso);
CREATE INDEX IF NOT EXISTS idx_historial_estado     ON unab.historial_academico(estado);
CREATE INDEX IF NOT EXISTS idx_historial_periodo    ON unab.historial_academico(periodo);

COMMENT ON TABLE unab.historial_academico IS 'Notas y estados por asignatura y periodo';

-- ----------------------------------------------------------------------------
-- 7. Calendario académico (sincronizado desde Google Sheets)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.calendario_academico (
    id            BIGSERIAL PRIMARY KEY,
    id_periodo    INT REFERENCES unab.periodos_academicos(id_periodo) ON DELETE SET NULL,
    evento        VARCHAR(200) NOT NULL,
    categoria     VARCHAR(50),   -- matricula | examenes | clases | pagos | ceremonia | general
    fecha_inicio  DATE NOT NULL,
    fecha_fin     DATE,
    descripcion   TEXT,
    publico       BOOLEAN DEFAULT TRUE,
    fuente        VARCHAR(100) DEFAULT 'Google Sheets',
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_calendario_fechas ON unab.calendario_academico(fecha_inicio, fecha_fin);

COMMENT ON TABLE unab.calendario_academico IS 'Eventos oficiales del calendario académico UNAB';

-- ----------------------------------------------------------------------------
-- 8. Noticias y convocatorias (scraping + notificaciones)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.noticias (
    id                 BIGSERIAL PRIMARY KEY,
    titulo             VARCHAR(300) NOT NULL,
    resumen            TEXT,
    contenido          TEXT,
    url                TEXT UNIQUE,
    fuente             VARCHAR(120),
    categoria          VARCHAR(60),  -- convocatoria | noticia | evento | beca | curso
    fecha_publicacion  DATE,
    fecha_scrape       TIMESTAMPTZ DEFAULT NOW(),
    activo             BOOLEAN DEFAULT TRUE,
    notificada         BOOLEAN DEFAULT FALSE
);

CREATE INDEX IF NOT EXISTS idx_noticias_fecha ON unab.noticias(fecha_publicacion DESC);

COMMENT ON TABLE unab.noticias IS 'Noticias/convocatorias UNAB obtenidas por scraping';

-- ----------------------------------------------------------------------------
-- 9. Conversaciones (auditoría, memoria y métricas del chatbot)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.conversaciones (
    id             BIGSERIAL PRIMARY KEY,
    session_id     VARCHAR(100) NOT NULL,
    canal          VARCHAR(20) DEFAULT 'android',  -- android | web | telegram | n8n
    id_estudiante  VARCHAR(15) REFERENCES unab.estudiantes(id_estudiante) ON DELETE SET NULL,
    pregunta       TEXT NOT NULL,
    respuesta      TEXT,
    tipo           VARCHAR(50),  -- rag | calendario | academico | noticias | menu | guardrail
    fuentes        JSONB DEFAULT '[]'::jsonb,
    tokens_usados  INT DEFAULT 0,
    latencia_ms    INT DEFAULT 0,
    feedback       SMALLINT,     -- -1 (malo) | 1 (bueno)
    created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversaciones_session ON unab.conversaciones(session_id);
CREATE INDEX IF NOT EXISTS idx_conversaciones_fecha   ON unab.conversaciones(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversaciones_tipo    ON unab.conversaciones(tipo);

COMMENT ON TABLE unab.conversaciones IS 'Historial de interacciones para auditoría y evaluación del RAG';

-- ----------------------------------------------------------------------------
-- 10. Solicitudes / casos de soporte
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.solicitudes (
    id                BIGSERIAL PRIMARY KEY,
    id_estudiante     VARCHAR(15) REFERENCES unab.estudiantes(id_estudiante) ON DELETE SET NULL,
    nombre_estudiante VARCHAR(200),
    tipo_solicitud    VARCHAR(100) NOT NULL,
    descripcion       TEXT,
    estado            VARCHAR(20) DEFAULT 'pendiente',  -- pendiente | en_proceso | resuelta | cerrada
    prioridad         VARCHAR(10) DEFAULT 'media',      -- baja | media | alta
    asignado_a        VARCHAR(120),
    enviado_sheets    BOOLEAN DEFAULT FALSE,
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON unab.solicitudes(estado, prioridad);

COMMENT ON TABLE unab.solicitudes IS 'Casos escalados a Bienestar/Registro Académico';

-- ----------------------------------------------------------------------------
-- 11. Notificaciones in-app / push
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.notificaciones (
    id             BIGSERIAL PRIMARY KEY,
    id_estudiante  VARCHAR(15) REFERENCES unab.estudiantes(id_estudiante) ON DELETE CASCADE,
    titulo         VARCHAR(200) NOT NULL,
    mensaje        TEXT,
    tipo           VARCHAR(50) DEFAULT 'general',  -- calendario | noticia | alerta_academica
    referencia_id  BIGINT,
    leida          BOOLEAN DEFAULT FALSE,
    enviada_push   BOOLEAN DEFAULT FALSE,
    created_at     TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notificaciones_estudiante
    ON unab.notificaciones(id_estudiante, leida);

-- ----------------------------------------------------------------------------
-- 12. Dispositivos para notificaciones push (FCM)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS unab.dispositivos (
    id             SERIAL PRIMARY KEY,
    id_estudiante  VARCHAR(15) REFERENCES unab.estudiantes(id_estudiante) ON DELETE CASCADE,
    fcm_token      TEXT UNIQUE NOT NULL,
    plataforma     VARCHAR(20) DEFAULT 'android',
    activo         BOOLEAN DEFAULT TRUE,
    updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- 13. Trigger genérico para updated_at
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unab.fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_estudiantes_updated ON unab.estudiantes;
CREATE TRIGGER trg_estudiantes_updated
    BEFORE UPDATE ON unab.estudiantes
    FOR EACH ROW EXECUTE FUNCTION unab.fn_set_updated_at();

DROP TRIGGER IF EXISTS trg_solicitudes_updated ON unab.solicitudes;
CREATE TRIGGER trg_solicitudes_updated
    BEFORE UPDATE ON unab.solicitudes
    FOR EACH ROW EXECUTE FUNCTION unab.fn_set_updated_at();

-- ============================================================================
-- FIN 01_schema.sql
-- ============================================================================
