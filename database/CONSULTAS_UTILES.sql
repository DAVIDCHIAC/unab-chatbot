-- Consultas útiles para explorar la base de datos UNAB en Supabase.
-- Pegar en SQL Editor. Esquema: unab. Datos sintéticos.

-- 1. Todas las tablas y sus conteos
SELECT table_name FROM information_schema.tables
WHERE table_schema='unab' AND table_type='BASE TABLE' ORDER BY table_name;

-- 2. Programas académicos
SELECT * FROM unab.programas ORDER BY nombre;

-- 3. Materias (cursos) con código, nombre, créditos y semestre
SELECT codigo_curso, nombre, creditos, semestre_sugerido, area
FROM unab.cursos ORDER BY semestre_sugerido, codigo_curso;

-- 4. Estudiantes (aquí están los id, por ejemplo 10045234)
SELECT id_estudiante, nombre, apellido, id_programa
FROM unab.estudiantes ORDER BY id_estudiante;

-- 5. Prerrequisitos: qué materia bloquea a cuál
SELECT * FROM unab.prerrequisitos ORDER BY codigo_curso;

-- 6. Historial de notas de un estudiante
SELECT * FROM unab.historial_academico
WHERE id_estudiante='10045234' ORDER BY periodo DESC;

-- 7. Resumen académico (vista)
SELECT * FROM unab.v_estado_estudiante WHERE id_estudiante='10045234';
SELECT * FROM unab.v_avance_plan WHERE id_estudiante='10045234';
SELECT * FROM unab.v_alertas_academicas WHERE id_estudiante='10045234';
SELECT * FROM unab.v_prerrequisitos_pendientes WHERE id_estudiante='10045234';

-- 8. Calendario y noticias
SELECT * FROM unab.calendario_academico ORDER BY fecha_inicio;
SELECT titulo, url, publicado_en FROM unab.noticias ORDER BY publicado_en DESC LIMIT 20;

-- 9. Base vectorial: extensión, índice y chunks (sin imprimir el vector)
SELECT extname, extversion FROM pg_extension WHERE extname='vector';
SELECT indexname, indexdef FROM pg_indexes
WHERE schemaname='unab' AND tablename='documentos_vectoriales';

SELECT id,
       left(content, 90) AS contenido,
       metadata->>'fuente' AS fuente,
       metadata->>'titulo' AS titulo,
       metadata->>'chunk' AS chunk,
       metadata->>'modelo' AS modelo,
       metadata->>'dimensiones' AS dimensiones,
       metadata->>'overlap' AS overlap
FROM unab.documentos_vectoriales
ORDER BY metadata->>'fuente', (metadata->>'chunk')::int LIMIT 30;

-- 10. Búsqueda por similitud coseno (usa un vector existente como consulta)
SELECT id, contenido, metadata, similitud
FROM unab.buscar_conocimiento(
  (SELECT embedding FROM unab.documentos_vectoriales LIMIT 1),
  5
);

-- 11. Conversaciones guardadas por el chatbot
SELECT id, session_id, id_estudiante, canal, pregunta, latencia_ms, creado_en
FROM unab.conversaciones ORDER BY creado_en DESC LIMIT 20;
