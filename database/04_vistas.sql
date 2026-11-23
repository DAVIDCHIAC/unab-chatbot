-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 04_vistas.sql
-- DESCRIPCIÓN:
--   Vistas analíticas optimizadas para que los agentes (FastMCP / n8n)
--   consulten en una sola llamada el estado, avance, proyección y alertas
--   del estudiante.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Estado general del estudiante
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_estado_estudiante AS
SELECT
    e.id_estudiante,
    e.nombre || ' ' || e.apellido                AS nombre_completo,
    e.email,
    e.telefono,
    p.codigo                                     AS codigo_programa,
    p.nombre                                     AS programa,
    e.semestre_actual,
    e.fecha_ingreso,
    e.estado                                     AS estado_estudiante,
    e.promedio_acumulado,
    COUNT(h.id)                                  AS cursos_registrados,
    COUNT(*) FILTER (WHERE h.estado IN ('aprobado','homologado')) AS cursos_aprobados,
    COUNT(*) FILTER (WHERE h.estado = 'en_curso')                 AS cursos_en_curso,
    COUNT(*) FILTER (WHERE h.estado = 'reprobado')                AS cursos_reprobados,
    COALESCE(SUM(h.creditos) FILTER (WHERE h.estado IN ('aprobado','homologado')), 0) AS creditos_aprobados,
    COALESCE(SUM(h.creditos) FILTER (WHERE h.estado = 'en_curso'), 0)                 AS creditos_en_curso
FROM unab.estudiantes e
LEFT JOIN unab.programas p ON p.id_programa = e.id_programa
LEFT JOIN unab.historial_academico h ON h.id_estudiante = e.id_estudiante
GROUP BY e.id_estudiante, e.nombre, e.apellido, e.email, e.telefono,
         p.codigo, p.nombre, e.semestre_actual, e.fecha_ingreso,
         e.estado, e.promedio_acumulado;

COMMENT ON VIEW unab.v_estado_estudiante IS 'Resumen consolidado por estudiante';

-- ----------------------------------------------------------------------------
-- 2. Avance del plan de estudios
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_avance_plan AS
SELECT
    e.id_estudiante,
    e.nombre || ' ' || e.apellido AS nombre_completo,
    p.nombre                      AS programa,
    p.creditos_totales,
    p.semestres_totales,
    e.semestre_actual,
    e.creditos_aprobados,
    GREATEST(p.creditos_totales - e.creditos_aprobados, 0) AS creditos_pendientes,
    ROUND(100.0 * e.creditos_aprobados / NULLIF(p.creditos_totales, 0), 1) AS porcentaje_avance,
    e.promedio_acumulado
FROM unab.estudiantes e
JOIN unab.programas p ON p.id_programa = e.id_programa;

COMMENT ON VIEW unab.v_avance_plan IS 'Créditos aprobados vs. totales y porcentaje de avance';

-- ----------------------------------------------------------------------------
-- 3. Proyección de semestres restantes
--    Usa el ritmo real del estudiante (créditos aprobados / semestres
--    cursados), con un mínimo de 12 créditos por semestre para no proyectar
--    escenarios irreales.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_proyeccion_semestres AS
WITH base AS (
    SELECT
        e.id_estudiante,
        e.nombre || ' ' || e.apellido AS nombre_completo,
        p.nombre                      AS programa,
        p.creditos_totales,
        p.semestres_totales,
        e.semestre_actual,
        GREATEST(e.semestre_actual - 1, 1) AS semestres_cursados,
        COALESCE(SUM(h.creditos) FILTER (WHERE h.estado IN ('aprobado','homologado')), 0) AS creditos_aprobados,
        COALESCE(SUM(h.creditos) FILTER (WHERE h.estado = 'en_curso'), 0)                 AS creditos_en_curso
    FROM unab.estudiantes e
    JOIN unab.programas p ON p.id_programa = e.id_programa
    LEFT JOIN unab.historial_academico h ON h.id_estudiante = e.id_estudiante
    GROUP BY e.id_estudiante, e.nombre, e.apellido, p.nombre, p.creditos_totales,
             p.semestres_totales, e.semestre_actual
), calculo AS (
    SELECT
        *,
        ROUND(creditos_aprobados::NUMERIC / semestres_cursados, 1) AS ritmo_creditos_semestre,
        GREATEST(creditos_totales - creditos_aprobados - creditos_en_curso, 0) AS creditos_restantes
    FROM base
)
SELECT
    id_estudiante,
    nombre_completo,
    programa,
    semestre_actual,
    creditos_totales,
    creditos_aprobados,
    creditos_en_curso,
    creditos_restantes,
    ritmo_creditos_semestre,
    CEIL(creditos_restantes::NUMERIC / GREATEST(ritmo_creditos_semestre, 12)) AS semestres_restantes_estimados,
    semestre_actual + CEIL(creditos_restantes::NUMERIC / GREATEST(ritmo_creditos_semestre, 12)) AS semestre_proyectado_grado,
    ROUND(100.0 * creditos_aprobados / NULLIF(creditos_totales, 0), 1) AS porcentaje_avance
FROM calculo;

COMMENT ON VIEW unab.v_proyeccion_semestres IS
    'Estimación de semestres restantes y semestre proyectado de grado';

-- ----------------------------------------------------------------------------
-- 4. Historial detallado (con datos del curso)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_historial_detalle AS
SELECT
    h.id,
    h.id_estudiante,
    c.codigo_curso,
    c.nombre          AS curso,
    c.creditos,
    c.semestre_sugerido,
    c.area,
    h.periodo,
    h.nota,
    h.estado,
    h.intento,
    h.docente
FROM unab.historial_academico h
JOIN unab.cursos c ON c.id_curso = h.id_curso;

COMMENT ON VIEW unab.v_historial_detalle IS 'Historial académico enriquecido con el nombre del curso';

-- ----------------------------------------------------------------------------
-- 5. Cursos pendientes (ni aprobados ni en curso)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_cursos_pendientes AS
SELECT
    e.id_estudiante,
    e.nombre || ' ' || e.apellido AS nombre_completo,
    c.codigo_curso,
    c.nombre       AS curso_pendiente,
    c.creditos,
    c.semestre_sugerido,
    c.tipo,
    c.area
FROM unab.estudiantes e
JOIN unab.cursos c ON c.id_programa = e.id_programa
WHERE NOT EXISTS (
    SELECT 1
    FROM unab.historial_academico h
    WHERE h.id_estudiante = e.id_estudiante
      AND h.id_curso = c.id_curso
      AND h.estado IN ('aprobado','homologado','en_curso')
)
ORDER BY e.id_estudiante, c.semestre_sugerido, c.codigo_curso;

COMMENT ON VIEW unab.v_cursos_pendientes IS 'Asignaturas que el estudiante aún no ha aprobado ni matriculado';

-- ----------------------------------------------------------------------------
-- 6. Prerrequisitos pendientes (cursos bloqueados)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_prerrequisitos_pendientes AS
SELECT
    e.id_estudiante,
    e.nombre || ' ' || e.apellido AS nombre_completo,
    c.codigo_curso                AS curso_bloqueado,
    c.nombre                      AS nombre_curso,
    c.semestre_sugerido,
    pr.codigo_curso               AS codigo_prerequisito,
    pr.nombre                     AS nombre_prerequisito,
    COALESCE(h.estado, 'pendiente') AS estado_prerequisito,
    CASE
        WHEN COALESCE(h.estado, 'pendiente') = 'reprobado' THEN 'prerrequisito_reprobado'
        WHEN COALESCE(h.estado, 'pendiente') = 'en_curso'  THEN 'prerrequisito_en_curso'
        ELSE 'prerrequisito_pendiente'
    END AS tipo_bloqueo,
    h.nota                        AS nota_prerequisito
FROM unab.estudiantes e
JOIN unab.cursos c          ON c.id_programa = e.id_programa
JOIN unab.prerrequisitos r  ON r.id_curso = c.id_curso
JOIN unab.cursos pr         ON pr.id_curso = r.id_prerrequisito
LEFT JOIN LATERAL (
    SELECT hh.estado, hh.nota
    FROM unab.historial_academico hh
    WHERE hh.id_estudiante = e.id_estudiante
      AND hh.id_curso = pr.id_curso
    ORDER BY hh.periodo DESC, hh.intento DESC
    LIMIT 1
) h ON TRUE
WHERE NOT EXISTS (
        SELECT 1
        FROM unab.historial_academico h2
        WHERE h2.id_estudiante = e.id_estudiante
          AND h2.id_curso = c.id_curso
          AND h2.estado IN ('aprobado','homologado','en_curso')
      )
  AND COALESCE(h.estado, 'pendiente') NOT IN ('aprobado','homologado')
  -- Solo cursos relevantes en el corto plazo (semestre actual o el siguiente)
  AND c.semestre_sugerido <= e.semestre_actual + 1
ORDER BY e.id_estudiante, c.semestre_sugerido;

COMMENT ON VIEW unab.v_prerrequisitos_pendientes IS
    'Cursos que no se pueden matricular porque su prerrequisito no está aprobado';

-- ----------------------------------------------------------------------------
-- 7. Alertas académicas por estudiante
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_alertas_academicas AS
SELECT
    e.id_estudiante,
    e.nombre || ' ' || e.apellido AS nombre_completo,
    e.semestre_actual,
    e.promedio_acumulado,
    (SELECT COUNT(*) FROM unab.historial_academico h
      WHERE h.id_estudiante = e.id_estudiante AND h.estado = 'reprobado') AS cursos_reprobados,
    (SELECT COUNT(DISTINCT pp.curso_bloqueado) FROM unab.v_prerrequisitos_pendientes pp
      WHERE pp.id_estudiante = e.id_estudiante) AS cursos_bloqueados,
    (SELECT COUNT(*) FROM unab.historial_academico h
      WHERE h.id_estudiante = e.id_estudiante AND h.estado = 'en_curso') AS cursos_en_curso,
    ARRAY_REMOVE(ARRAY[
        CASE WHEN e.promedio_acumulado > 0 AND e.promedio_acumulado < 3.2
             THEN 'Promedio en riesgo (< 3.2)' END,
        CASE WHEN (SELECT COUNT(*) FROM unab.historial_academico h
                    WHERE h.id_estudiante = e.id_estudiante AND h.estado = 'reprobado') > 0
             THEN 'Tiene asignaturas reprobadas' END,
        CASE WHEN (SELECT COUNT(*) FROM unab.v_prerrequisitos_pendientes pp
                    WHERE pp.id_estudiante = e.id_estudiante) > 0
             THEN 'Tiene cursos bloqueados por prerrequisito' END,
        CASE WHEN e.semestre_actual >= 8
              AND (SELECT COUNT(*) FROM unab.historial_academico h
                    WHERE h.id_estudiante = e.id_estudiante
                      AND h.estado IN ('aprobado','homologado')) < 30
             THEN 'Avance bajo para el semestre en curso' END
    ], NULL) AS alertas
FROM unab.estudiantes e
WHERE e.estado = 'activo';

COMMENT ON VIEW unab.v_alertas_academicas IS 'Alertas de riesgo académico y bloqueos por prerrequisito';

-- ----------------------------------------------------------------------------
-- 8. Calendario próximo (eventos vigentes o futuros)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_calendario_proximo AS
SELECT
    ca.id,
    pa.codigo AS periodo,
    ca.evento,
    ca.categoria,
    ca.fecha_inicio,
    ca.fecha_fin,
    ca.descripcion,
    (ca.fecha_inicio - CURRENT_DATE) AS dias_faltantes
FROM unab.calendario_academico ca
LEFT JOIN unab.periodos_academicos pa ON pa.id_periodo = ca.id_periodo
WHERE ca.publico = TRUE
  AND COALESCE(ca.fecha_fin, ca.fecha_inicio) >= CURRENT_DATE
ORDER BY ca.fecha_inicio;

COMMENT ON VIEW unab.v_calendario_proximo IS 'Próximos eventos públicos del calendario académico';

-- ----------------------------------------------------------------------------
-- 9. Noticias recientes
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_noticias_recientes AS
SELECT
    n.id,
    n.titulo,
    n.resumen,
    n.url,
    n.fuente,
    n.categoria,
    n.fecha_publicacion,
    (CURRENT_DATE - n.fecha_publicacion) AS dias_publicada
FROM unab.noticias n
WHERE n.activo = TRUE
ORDER BY n.fecha_publicacion DESC NULLS LAST;

COMMENT ON VIEW unab.v_noticias_recientes IS 'Noticias y convocatorias activas ordenadas por fecha';

-- ----------------------------------------------------------------------------
-- 10. Malla curricular del programa
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_malla_curricular AS
SELECT
    p.codigo AS codigo_programa,
    p.nombre AS programa,
    c.semestre_sugerido,
    c.codigo_curso,
    c.nombre AS curso,
    c.creditos,
    c.tipo,
    c.area,
    COALESCE(
        (SELECT STRING_AGG(pr.codigo_curso, ', ' ORDER BY pr.codigo_curso)
         FROM unab.prerrequisitos r
         JOIN unab.cursos pr ON pr.id_curso = r.id_prerrequisito
         WHERE r.id_curso = c.id_curso),
        '—'
    ) AS prerrequisitos
FROM unab.cursos c
JOIN unab.programas p ON p.id_programa = c.id_programa
WHERE c.activo = TRUE
ORDER BY p.codigo, c.semestre_sugerido, c.codigo_curso;

COMMENT ON VIEW unab.v_malla_curricular IS 'Pensum con prerrequisitos consolidados por curso';

-- ----------------------------------------------------------------------------
-- 11. KPIs del chatbot (dashboard)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW unab.v_kpis_chatbot AS
SELECT
    COUNT(*)                                                    AS total_conversaciones,
    COUNT(DISTINCT session_id)                                  AS sesiones_unicas,
    COUNT(*) FILTER (WHERE created_at::DATE = CURRENT_DATE)     AS conversaciones_hoy,
    COUNT(*) FILTER (WHERE tipo = 'rag')                        AS consultas_rag,
    COUNT(*) FILTER (WHERE tipo = 'academico')                  AS consultas_academicas,
    COUNT(*) FILTER (WHERE tipo = 'calendario')                 AS consultas_calendario,
    COUNT(*) FILTER (WHERE tipo = 'noticias')                   AS consultas_noticias,
    ROUND(AVG(latencia_ms), 0)                                  AS latencia_promedio_ms,
    COUNT(*) FILTER (WHERE feedback = 1)                        AS feedback_positivo,
    COUNT(*) FILTER (WHERE feedback = -1)                       AS feedback_negativo
FROM unab.conversaciones;

COMMENT ON VIEW unab.v_kpis_chatbot IS 'Indicadores de uso y calidad del chatbot';

-- ============================================================================
-- FIN 04_vistas.sql
-- ============================================================================
