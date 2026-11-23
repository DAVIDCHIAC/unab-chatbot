-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 06_consultas_demo.sql
-- DESCRIPCIÓN:
--   Consultas de verificación y demostración. Úsalas en el SQL Editor de
--   Supabase para tomar los pantallazos del README y del video.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ¿Qué estudiantes existen? (elige uno para las pruebas)
-- ----------------------------------------------------------------------------
SELECT id_estudiante, nombre || ' ' || apellido AS nombre, semestre_actual, promedio_acumulado
FROM unab.estudiantes
ORDER BY semestre_actual DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 2. Estado académico consolidado
-- ----------------------------------------------------------------------------
SELECT *
FROM unab.v_estado_estudiante
WHERE id_estudiante = '10045231';

-- ----------------------------------------------------------------------------
-- 3. Avance del plan de estudios
-- ----------------------------------------------------------------------------
SELECT *
FROM unab.v_avance_plan
WHERE id_estudiante = '10045231';

-- ----------------------------------------------------------------------------
-- 4. Proyección de semestres restantes
-- ----------------------------------------------------------------------------
SELECT *
FROM unab.v_proyeccion_semestres
WHERE id_estudiante = '10045231';

-- ----------------------------------------------------------------------------
-- 5. Historial detallado (materias, notas y estados)
-- ----------------------------------------------------------------------------
SELECT codigo_curso, curso, creditos, periodo, nota, estado
FROM unab.v_historial_detalle
WHERE id_estudiante = '10045231'
ORDER BY periodo, codigo_curso;

-- ----------------------------------------------------------------------------
-- 6. Cursos pendientes
-- ----------------------------------------------------------------------------
SELECT codigo_curso, curso_pendiente, creditos, semestre_sugerido, tipo
FROM unab.v_cursos_pendientes
WHERE id_estudiante = '10045231'
ORDER BY semestre_sugerido;

-- ----------------------------------------------------------------------------
-- 7. Cursos bloqueados por prerrequisito
-- ----------------------------------------------------------------------------
SELECT curso_bloqueado, nombre_curso, codigo_prerequisito,
       nombre_prerequisito, estado_prerequisito, nota_prerequisito
FROM unab.v_prerrequisitos_pendientes
WHERE id_estudiante = '10045231';

-- ----------------------------------------------------------------------------
-- 8. Alertas académicas
-- ----------------------------------------------------------------------------
SELECT *
FROM unab.v_alertas_academicas
WHERE cardinality(alertas) > 0
ORDER BY cursos_bloqueados DESC, cursos_reprobados DESC;

-- ----------------------------------------------------------------------------
-- 9. Próximos eventos del calendario
-- ----------------------------------------------------------------------------
SELECT evento, categoria, fecha_inicio, fecha_fin, dias_faltantes
FROM unab.v_calendario_proximo
LIMIT 10;

-- ----------------------------------------------------------------------------
-- 10. Noticias recientes
-- ----------------------------------------------------------------------------
SELECT titulo, categoria, fecha_publicacion, url
FROM unab.v_noticias_recientes
LIMIT 5;

-- ----------------------------------------------------------------------------
-- 11. Malla curricular de Ingeniería de Sistemas
-- ----------------------------------------------------------------------------
SELECT semestre_sugerido, codigo_curso, curso, creditos, prerrequisitos
FROM unab.v_malla_curricular
WHERE codigo_programa = 'ING-SIS'
ORDER BY semestre_sugerido, codigo_curso;

-- ----------------------------------------------------------------------------
-- 12. Búsqueda vectorial (requiere documentos cargados por el WF de ingesta)
--     Reemplaza el vector por el embedding real de la pregunta.
-- ----------------------------------------------------------------------------
-- SELECT contenido, metadata, similitud
-- FROM unab.buscar_conocimiento(
--     (SELECT embedding FROM unab.documentos_vectoriales LIMIT 1),
--     5,
--     '{}'::jsonb
-- );

-- ----------------------------------------------------------------------------
-- 13. KPIs del chatbot
-- ----------------------------------------------------------------------------
SELECT * FROM unab.v_kpis_chatbot;

-- ============================================================================
-- FIN 06_consultas_demo.sql
-- ============================================================================
