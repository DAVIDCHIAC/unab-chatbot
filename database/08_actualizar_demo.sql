-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 08_actualizar_demo.sql
-- DESCRIPCIÓN:
--   Mantiene la demo "siempre vigente". Recalcula el periodo activo y
--   regenera el calendario y las noticias de ejemplo tomando como referencia
--   CURRENT_DATE, de modo que el chatbot siempre muestre eventos y noticias
--   próximos (no fechas del pasado).
--
--   Es idempotente: se puede ejecutar antes de cada demo o grabación.
--   No modifica el historial académico ni los datos del pensum.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Periodo académico vigente (según el mes actual)
--    Enero–junio  -> AAAA-1
--    Julio–diciembre -> AAAA-2
-- ----------------------------------------------------------------------------
DROP TABLE IF EXISTS pg_temp.periodo_vigente;
CREATE TEMP TABLE periodo_vigente AS
SELECT
    CASE WHEN EXTRACT(MONTH FROM CURRENT_DATE) >= 7
         THEN EXTRACT(YEAR FROM CURRENT_DATE)::INT::TEXT || '-2'
         ELSE EXTRACT(YEAR FROM CURRENT_DATE)::INT::TEXT || '-1'
    END AS codigo,
    CASE WHEN EXTRACT(MONTH FROM CURRENT_DATE) >= 7
         THEN make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 7, 15)
         ELSE make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 1, 15)
    END AS inicio,
    CASE WHEN EXTRACT(MONTH FROM CURRENT_DATE) >= 7
         THEN make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 11, 30)
         ELSE make_date(EXTRACT(YEAR FROM CURRENT_DATE)::INT, 6, 15)
    END AS fin;

INSERT INTO unab.periodos_academicos (codigo, nombre, fecha_inicio, fecha_fin, activo)
SELECT
    codigo,
    CASE WHEN codigo LIKE '%-1' THEN 'Primer semestre ' ELSE 'Segundo semestre ' END
        || split_part(codigo, '-', 1),
    inicio,
    fin,
    TRUE
FROM periodo_vigente
ON CONFLICT (codigo) DO UPDATE
SET nombre       = EXCLUDED.nombre,
    fecha_inicio = EXCLUDED.fecha_inicio,
    fecha_fin    = EXCLUDED.fecha_fin,
    activo       = TRUE;

UPDATE unab.periodos_academicos
SET activo = (codigo = (SELECT codigo FROM periodo_vigente));

-- ----------------------------------------------------------------------------
-- 2. Calendario: borrar solo los eventos generados por este script
-- ----------------------------------------------------------------------------
DELETE FROM unab.calendario_academico WHERE fuente = 'demo-dinamico';

INSERT INTO unab.calendario_academico
    (id_periodo, evento, categoria, fecha_inicio, fecha_fin, descripcion, fuente)
SELECT
    (SELECT id_periodo FROM unab.periodos_academicos
      WHERE codigo = (SELECT codigo FROM periodo_vigente)),
    v.evento,
    v.categoria,
    CURRENT_DATE + v.dias,
    CURRENT_DATE + v.dias_fin,
    v.descripcion,
    'demo-dinamico'
FROM (VALUES
    ('Matrícula: inscripción de asignaturas del próximo periodo', 'matricula', 28, 38,
     'Inscripción en línea de asignaturas por COSMOS. Revisa tus prerrequisitos antes de matricular.'),
    ('Pago de matrícula del próximo periodo', 'pagos', 28, 45,
     'Plazo para el pago de la matrícula ordinaria y reporte del recibo.'),
    ('Publicación de notas del semestre', 'general', 12, 12,
     'Consulta de calificaciones finales en COSMOS.'),
    ('Exámenes finales', 'examenes', 4, 11,
     'Semana de evaluaciones finales. Consulta el horario publicado por tu facultad.'),
    ('Ceremonia de grados', 'ceremonia', 20, 20,
     'Grados de pregrado y posgrado. Requiere paz y salvo y solicitud radicada.'),
    ('Inicio de clases del próximo periodo', 'clases', 52, 52,
     'Primer día de actividades académicas del nuevo semestre.'),
    ('Fecha límite de adición y retiro de asignaturas', 'matricula', 66, 66,
     'Último día para adicionar o retirar asignaturas sin afectar el historial.'),
    ('Primer corte evaluativo', 'examenes', 80, 84,
     'Semana de evaluaciones del primer corte.'),
    ('Segundo corte evaluativo', 'examenes', 108, 112,
     'Semana de evaluaciones del segundo corte.'),
    ('Último día de clases', 'clases', 136, 136,
     'Finalización de actividades docentes del semestre.'),
    ('Exámenes finales del siguiente ciclo', 'examenes', 140, 149,
     'Evaluaciones finales del semestre en curso.'),
    ('Publicación de notas y habilitaciones', 'general', 156, 156,
     'Publicación de notas finales y fechas de habilitación.'),
    ('Ceremonia de grados del siguiente ciclo', 'ceremonia', 166, 166,
     'Grados de pregrado y posgrado del cierre de semestre.')
) AS v(evento, categoria, dias, dias_fin, descripcion);

-- ----------------------------------------------------------------------------
-- 3. Noticias y convocatorias recientes (fechas relativas a hoy)
-- ----------------------------------------------------------------------------
INSERT INTO unab.noticias
    (titulo, resumen, contenido, url, fuente, categoria, fecha_publicacion)
VALUES
('Inscripciones abiertas para el semillero de inteligencia artificial',
 'El semillero de IA del programa de Ingeniería de Sistemas recibe nuevos integrantes.',
 'Los estudiantes interesados en machine learning, visión por computador o procesamiento de lenguaje natural pueden postularse al semillero. Se requieren ganas de aprender y disponibilidad de cuatro horas semanales. La inscripción se realiza con el profesor líder del semillero.',
 'https://www.unab.edu.co/noticias/semillero-ia', 'UNAB', 'convocatoria',
 CURRENT_DATE - 2),
('Nuevo horario de atención de Registro Académico',
 'La Oficina de Registro Académico amplía su atención presencial y virtual.',
 'A partir de este mes la atención presencial es de lunes a viernes de 7:00 a 17:00 y la atención virtual de 8:00 a 18:00. Los trámites de certificados y solicitudes de grado se pueden radicar en COSMOS sin fila.',
 'https://www.unab.edu.co/noticias/registro-academico-horario', 'UNAB', 'noticia',
 CURRENT_DATE - 6),
('Taller de preparación para exámenes finales',
 'Bienestar Universitario y el CCD ofrecen un taller gratuito de técnicas de estudio.',
 'El taller cubre organización del tiempo, métodos de repaso activo y manejo de ansiedad antes de los exámenes. Se realiza en modalidad híbrida y tiene cupos limitados. Inscríbete en el portal de Bienestar Universitario.',
 'https://www.unab.edu.co/noticias/taller-examenes-finales', 'UNAB', 'evento',
 CURRENT_DATE - 9),
('Convocatoria de apoyo económico para transporte',
 'La UNAB abre apoyos de transporte para estudiantes con dificultades económicas.',
 'El apoyo cubre parte del costo de transporte durante el semestre. Pueden postularse estudiantes matriculados con carga académica igual o superior a 12 créditos que acrediten necesidad económica. La documentación se radica en Bienestar Universitario.',
 'https://www.unab.edu.co/noticias/apoyo-transporte', 'UNAB', 'beca',
 CURRENT_DATE - 14)
ON CONFLICT (url) DO UPDATE
SET fecha_publicacion = EXCLUDED.fecha_publicacion,
    resumen           = EXCLUDED.resumen,
    contenido         = EXCLUDED.contenido;

COMMIT;

-- ----------------------------------------------------------------------------
-- 4. Verificación
-- ----------------------------------------------------------------------------
SELECT 'periodo_activo' AS dato,
       (SELECT codigo FROM unab.periodos_academicos WHERE activo LIMIT 1) AS valor
UNION ALL
SELECT 'eventos_proximos', COUNT(*)::TEXT FROM unab.v_calendario_proximo
UNION ALL
SELECT 'noticias_ultimos_30_dias', COUNT(*)::TEXT
FROM unab.noticias WHERE fecha_publicacion >= CURRENT_DATE - 30;

-- ============================================================================
-- FIN 08_actualizar_demo.sql
-- ============================================================================
