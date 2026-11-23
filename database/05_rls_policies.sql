-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 05_rls_policies.sql
-- DESCRIPCIÓN:
--   Row Level Security (RLS) para Supabase.
--   - Catálogo (programas, cursos, calendario, noticias): lectura pública.
--   - Datos personales (estudiante, historial, conversaciones, solicitudes,
--     notificaciones, dispositivos): solo el dueño del registro.
--   - Tabla vectorial: solo service_role (n8n / backend).
--
--   ⚠ Ejecutar DESPUÉS de 01..04 y con el rol "postgres" del SQL Editor.
--   ⚠ auth.uid() solo existe en Supabase (no en PostgreSQL puro).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Helper: id_estudiante del usuario autenticado
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unab.current_estudiante_id()
RETURNS VARCHAR
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = unab, public
AS $$
    SELECT id_estudiante
    FROM unab.estudiantes
    WHERE user_id = auth.uid()
    LIMIT 1;
$$;

COMMENT ON FUNCTION unab.current_estudiante_id IS
    'Devuelve el código del estudiante vinculado al usuario autenticado';

-- ----------------------------------------------------------------------------
-- 2. Permisos de esquema
-- ----------------------------------------------------------------------------
GRANT USAGE ON SCHEMA unab TO anon, authenticated, service_role;

GRANT SELECT ON
    unab.programas,
    unab.cursos,
    unab.prerrequisitos,
    unab.periodos_academicos,
    unab.calendario_academico,
    unab.noticias
TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE ON
    unab.estudiantes,
    unab.historial_academico,
    unab.conversaciones,
    unab.solicitudes,
    unab.notificaciones,
    unab.dispositivos
TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON
    unab.documentos,
    unab.documentos_vectoriales,
    unab.noticias
TO service_role;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA unab TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 3. Activar RLS
-- ----------------------------------------------------------------------------
ALTER TABLE unab.programas               ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.cursos                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.prerrequisitos          ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.periodos_academicos     ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.calendario_academico    ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.noticias                ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.estudiantes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.historial_academico     ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.conversaciones          ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.solicitudes             ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.notificaciones          ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.dispositivos            ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.documentos              ENABLE ROW LEVEL SECURITY;
ALTER TABLE unab.documentos_vectoriales  ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- 4. Catálogo público (solo lectura)
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "catalogo_programas_lectura" ON unab.programas;
CREATE POLICY "catalogo_programas_lectura"
    ON unab.programas FOR SELECT
    TO anon, authenticated
    USING (activo = TRUE);

DROP POLICY IF EXISTS "catalogo_cursos_lectura" ON unab.cursos;
CREATE POLICY "catalogo_cursos_lectura"
    ON unab.cursos FOR SELECT
    TO anon, authenticated
    USING (activo = TRUE);

DROP POLICY IF EXISTS "catalogo_prerrequisitos_lectura" ON unab.prerrequisitos;
CREATE POLICY "catalogo_prerrequisitos_lectura"
    ON unab.prerrequisitos FOR SELECT
    TO anon, authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "catalogo_periodos_lectura" ON unab.periodos_academicos;
CREATE POLICY "catalogo_periodos_lectura"
    ON unab.periodos_academicos FOR SELECT
    TO anon, authenticated
    USING (TRUE);

DROP POLICY IF EXISTS "catalogo_calendario_lectura" ON unab.calendario_academico;
CREATE POLICY "catalogo_calendario_lectura"
    ON unab.calendario_academico FOR SELECT
    TO anon, authenticated
    USING (publico = TRUE);

DROP POLICY IF EXISTS "catalogo_noticias_lectura" ON unab.noticias;
CREATE POLICY "catalogo_noticias_lectura"
    ON unab.noticias FOR SELECT
    TO anon, authenticated
    USING (activo = TRUE);

-- ----------------------------------------------------------------------------
-- 5. Datos personales: solo el dueño
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "estudiante_propio_lectura" ON unab.estudiantes;
CREATE POLICY "estudiante_propio_lectura"
    ON unab.estudiantes FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

DROP POLICY IF EXISTS "estudiante_propio_actualizacion" ON unab.estudiantes;
CREATE POLICY "estudiante_propio_actualizacion"
    ON unab.estudiantes FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "historial_propio_lectura" ON unab.historial_academico;
CREATE POLICY "historial_propio_lectura"
    ON unab.historial_academico FOR SELECT
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "conversaciones_propias_lectura" ON unab.conversaciones;
CREATE POLICY "conversaciones_propias_lectura"
    ON unab.conversaciones FOR SELECT
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "conversaciones_propias_insercion" ON unab.conversaciones;
CREATE POLICY "conversaciones_propias_insercion"
    ON unab.conversaciones FOR INSERT
    TO authenticated
    WITH CHECK (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "conversaciones_propio_feedback" ON unab.conversaciones;
CREATE POLICY "conversaciones_propio_feedback"
    ON unab.conversaciones FOR UPDATE
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id())
    WITH CHECK (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "solicitudes_propias_lectura" ON unab.solicitudes;
CREATE POLICY "solicitudes_propias_lectura"
    ON unab.solicitudes FOR SELECT
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "solicitudes_propias_insercion" ON unab.solicitudes;
CREATE POLICY "solicitudes_propias_insercion"
    ON unab.solicitudes FOR INSERT
    TO authenticated
    WITH CHECK (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "notificaciones_propias" ON unab.notificaciones;
CREATE POLICY "notificaciones_propias"
    ON unab.notificaciones FOR SELECT
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "notificaciones_propias_update" ON unab.notificaciones;
CREATE POLICY "notificaciones_propias_update"
    ON unab.notificaciones FOR UPDATE
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id())
    WITH CHECK (id_estudiante = unab.current_estudiante_id());

DROP POLICY IF EXISTS "dispositivos_propios" ON unab.dispositivos;
CREATE POLICY "dispositivos_propios"
    ON unab.dispositivos FOR ALL
    TO authenticated
    USING (id_estudiante = unab.current_estudiante_id())
    WITH CHECK (id_estudiante = unab.current_estudiante_id());

-- ----------------------------------------------------------------------------
-- 6. Documentos / vectores: SIN políticas para anon/authenticated
--    => solo service_role (que ignora RLS) puede leer o escribir.
--    El backend FastMCP y n8n usan la cadena de conexión directa.
-- ----------------------------------------------------------------------------

-- ============================================================================
-- FIN 05_rls_policies.sql
-- ============================================================================
