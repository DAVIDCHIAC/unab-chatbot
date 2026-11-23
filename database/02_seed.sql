-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 02_seed.sql
-- DESCRIPCIÓN:
--   Datos sintéticos para demostración:
--     - Programas académicos
--     - Pensum de Ingeniería de Sistemas (10 semestres)
--     - Prerrequisitos
--     - 30 estudiantes con historial académico generado
--     - Periodos, calendario académico y noticias de ejemplo
--
--   ⚠ Los datos son SINTÉTICOS. Reemplaza el pensum por el oficial cuando
--     lo tengas (misma estructura de columnas).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 0. Función auxiliar: periodo académico según semestre del pensum
--    Ej.: ingreso 2023-1 + semestre_sugerido 3  ->  '2024-1'
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION unab.periodo_por_semestre(p_ingreso DATE, p_semestre INT)
RETURNS VARCHAR
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
    v_anio  INT := EXTRACT(YEAR  FROM p_ingreso)::INT;
    v_sem   INT := CASE WHEN EXTRACT(MONTH FROM p_ingreso) <= 6 THEN 1 ELSE 2 END;
    v_total INT := v_sem + (p_semestre - 1);
BEGIN
    RETURN (v_anio + ((v_total - 1) / 2))::TEXT
           || '-' || ((((v_total - 1) % 2) + 1))::TEXT;
END;
$$;

-- ----------------------------------------------------------------------------
-- 1. Programas académicos
-- ----------------------------------------------------------------------------
INSERT INTO unab.programas (codigo, nombre, facultad, creditos_totales, semestres_totales) VALUES
('ING-SIS', 'Ingeniería de Sistemas',        'Facultad de Ingeniería',      160, 10),
('ING-IND', 'Ingeniería Industrial',         'Facultad de Ingeniería',      170, 10),
('ING-ELE', 'Ingeniería Electrónica',        'Facultad de Ingeniería',      168, 10),
('ING-MEC', 'Ingeniería Mecatrónica',        'Facultad de Ingeniería',      172, 10),
('ADM-EMP', 'Administración de Empresas',    'Ciencias Económicas',         155, 9),
('CONT',    'Contaduría Pública',            'Ciencias Económicas',         158, 9),
('DER',     'Derecho',                       'Ciencias Jurídicas',          165, 10),
('PSI',     'Psicología',                    'Ciencias de la Salud',        168, 10),
('MED',     'Medicina',                      'Ciencias de la Salud',        240, 12),
('COM-SOC', 'Comunicación Social',           'Ciencias Sociales',           152, 9),
('DIS-GRA', 'Diseño Gráfico',                'Ciencias Sociales',           150, 9),
('ARQ',     'Arquitectura',                  'Arquitectura',                180, 10)
ON CONFLICT (codigo) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 2. Pensum: Ingeniería de Sistemas
-- ----------------------------------------------------------------------------
INSERT INTO unab.cursos
    (id_programa, codigo_curso, nombre, creditos, semestre_sugerido, tipo, area, horas_teoria, horas_practica, descripcion)
SELECT p.id_programa, v.codigo, v.nombre, v.creditos, v.semestre, v.tipo, v.area, v.ht, v.hp, v.descripcion
FROM (VALUES
    -- Semestre 1
    ('IS101','Cálculo Diferencial',                    4, 1,'obligatorio','Ciencias Básicas',4,0,'Límites, derivadas y aplicaciones.'),
    ('IS102','Álgebra Lineal',                         3, 1,'obligatorio','Ciencias Básicas',3,0,'Matrices, sistemas de ecuaciones y espacios vectoriales.'),
    ('IS103','Introducción a la Ingeniería de Sistemas',2,1,'obligatorio','Ingeniería Aplicada',2,0,'Rol profesional y campos de acción.'),
    ('IS104','Programación I',                         4, 1,'obligatorio','Software',2,4,'Fundamentos de programación y pensamiento algorítmico.'),
    ('IS105','Competencias Comunicativas',             2, 1,'transversal','Humanidades',2,0,'Comunicación oral y escrita académica.'),
    ('IS106','Cátedra UNAB',                           1, 1,'transversal','Humanidades',1,0,'Identidad y vida universitaria.'),
    -- Semestre 2
    ('IS201','Cálculo Integral',                       4, 2,'obligatorio','Ciencias Básicas',4,0,'Integrales y aplicaciones.'),
    ('IS202','Física I',                               4, 2,'obligatorio','Ciencias Básicas',3,2,'Mecánica clásica.'),
    ('IS203','Programación II',                        4, 2,'obligatorio','Software',2,4,'Programación orientada a objetos.'),
    ('IS204','Estructuras Discretas',                  3, 2,'obligatorio','Ciencias Básicas',3,0,'Lógica, conjuntos, grafos y combinatoria.'),
    ('IS205','Estadística Descriptiva',                3, 2,'obligatorio','Ciencias Básicas',3,0,'Organización y análisis de datos.'),
    -- Semestre 3
    ('IS301','Cálculo Multivariado',                   4, 3,'obligatorio','Ciencias Básicas',4,0,'Funciones de varias variables.'),
    ('IS302','Física II',                              4, 3,'obligatorio','Ciencias Básicas',3,2,'Electricidad y magnetismo.'),
    ('IS303','Estructuras de Datos',                   4, 3,'obligatorio','Software',2,4,'Listas, árboles, grafos y complejidad.'),
    ('IS304','Bases de Datos I',                       3, 3,'obligatorio','Datos',2,2,'Modelo relacional y SQL.'),
    ('IS305','Arquitectura de Computadores',           3, 3,'obligatorio','Infraestructura',2,2,'Organización del hardware.'),
    -- Semestre 4
    ('IS401','Ecuaciones Diferenciales',               3, 4,'obligatorio','Ciencias Básicas',3,0,'EDO y aplicaciones en ingeniería.'),
    ('IS402','Bases de Datos II',                      3, 4,'obligatorio','Datos',2,2,'Normalización, transacciones e índices.'),
    ('IS403','Análisis de Algoritmos',                 3, 4,'obligatorio','Software',3,0,'Complejidad y diseño de algoritmos.'),
    ('IS404','Sistemas Operativos',                    3, 4,'obligatorio','Infraestructura',2,2,'Procesos, memoria y concurrencia.'),
    ('IS405','Ingeniería de Software I',               3, 4,'obligatorio','Software',2,2,'Requisitos y modelado.'),
    ('IS406','Probabilidad y Estadística',             3, 4,'obligatorio','Ciencias Básicas',3,0,'Variables aleatorias e inferencia.'),
    -- Semestre 5
    ('IS501','Redes de Computadores',                  3, 5,'obligatorio','Infraestructura',2,2,'Modelo TCP/IP y enrutamiento.'),
    ('IS502','Ingeniería de Software II',              3, 5,'obligatorio','Software',2,2,'Diseño, arquitectura y pruebas.'),
    ('IS503','Inteligencia Artificial',                3, 5,'obligatorio','Inteligencia Artificial',2,2,'Búsqueda, agentes y aprendizaje.'),
    ('IS504','Teoría de Lenguajes y Autómatas',        3, 5,'obligatorio','Ciencias Básicas',3,0,'Autómatas y gramáticas.'),
    ('IS505','Investigación de Operaciones',           3, 5,'obligatorio','Ciencias Básicas',3,0,'Optimización y modelos.'),
    ('IS506','Electiva Profesional I',                 3, 5,'electivo','Electivas',3,0,'Curso electivo de profundización.'),
    -- Semestre 6
    ('IS601','Seguridad Informática',                  3, 6,'obligatorio','Infraestructura',2,2,'Criptografía y seguridad de sistemas.'),
    ('IS602','Arquitectura de Software',               3, 6,'obligatorio','Software',2,2,'Patrones y estilos arquitectónicos.'),
    ('IS603','Compiladores',                           3, 6,'obligatorio','Software',2,2,'Análisis léxico, sintáctico y semántico.'),
    ('IS604','Gestión de Proyectos TI',                3, 6,'obligatorio','Gestión',2,2,'PMBOK, ágil y Scrum.'),
    ('IS605','Electiva Profesional II',                3, 6,'electivo','Electivas',3,0,'Curso electivo de profundización.'),
    ('IS606','Ética Profesional',                      2, 6,'transversal','Humanidades',2,0,'Ética y responsabilidad profesional.'),
    -- Semestre 7
    ('IS701','Computación en la Nube',                 3, 7,'obligatorio','Infraestructura',2,2,'IaaS, PaaS, SaaS y despliegue.'),
    ('IS702','Big Data',                               3, 7,'obligatorio','Datos',2,2,'Procesamiento distribuido de datos.'),
    ('IS703','Machine Learning',                       3, 7,'obligatorio','Inteligencia Artificial',2,2,'Modelos supervisados y no supervisados.'),
    ('IS704','DevOps y Automatización',                3, 7,'obligatorio','Software',2,2,'CI/CD, contenedores y observabilidad.'),
    ('IS705','Electiva Profesional III',               3, 7,'electivo','Electivas',3,0,'Curso electivo de profundización.'),
    ('IS706','Trabajo de Grado I',                     2, 7,'obligatorio','Investigación',1,2,'Formulación del proyecto de grado.'),
    -- Semestre 8
    ('IS801','Internet de las Cosas',                  3, 8,'obligatorio','Infraestructura',2,2,'Sensores, protocolos y edge computing.'),
    ('IS802','Desarrollo de Aplicaciones Móviles',     3, 8,'obligatorio','Software',2,2,'Android/Kotlin y consumo de APIs.'),
    ('IS803','Analítica de Datos',                     3, 8,'obligatorio','Datos',2,2,'Visualización y dashboards.'),
    ('IS804','Electiva Profesional IV',                3, 8,'electivo','Electivas',3,0,'Curso electivo de profundización.'),
    ('IS805','Trabajo de Grado II',                    3, 8,'obligatorio','Investigación',1,4,'Ejecución y sustentación.'),
    ('IS806','Práctica Profesional',                   6, 8,'obligatorio','Práctica',0,12,'Práctica en empresa.'),
    -- Semestre 9
    ('IS901','Emprendimiento e Innovación',            3, 9,'obligatorio','Gestión',2,2,'Modelos de negocio y innovación.'),
    ('IS902','Electiva Profesional V',                 3, 9,'electivo','Electivas',3,0,'Curso electivo de profundización.'),
    ('IS903','Seminario de Investigación',             2, 9,'obligatorio','Investigación',2,0,'Seminario de actualización.'),
    -- Semestre 10
    ('IS1001','Opción de Grado',                       6,10,'obligatorio','Investigación',0,12,'Modalidad de grado.'),
    ('IS1002','Electiva Profesional VI',               3,10,'electivo','Electivas',3,0,'Curso electivo de profundización.')
) AS v(codigo, nombre, creditos, semestre, tipo, area, ht, hp, descripcion)
JOIN unab.programas p ON p.codigo = 'ING-SIS'
ON CONFLICT (id_programa, codigo_curso) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 3. Prerrequisitos
-- ----------------------------------------------------------------------------
INSERT INTO unab.prerrequisitos (id_curso, id_prerrequisito)
SELECT c.id_curso, pr.id_curso
FROM (VALUES
    ('IS201','IS101'), ('IS202','IS101'), ('IS203','IS104'), ('IS204','IS102'),
    ('IS301','IS201'), ('IS302','IS202'), ('IS303','IS203'), ('IS303','IS204'),
    ('IS304','IS203'), ('IS305','IS203'),
    ('IS401','IS301'), ('IS402','IS304'), ('IS403','IS303'), ('IS404','IS305'),
    ('IS405','IS303'), ('IS406','IS205'),
    ('IS501','IS305'), ('IS502','IS405'), ('IS503','IS403'), ('IS504','IS204'),
    ('IS505','IS401'),
    ('IS601','IS501'), ('IS602','IS502'), ('IS603','IS504'), ('IS604','IS502'),
    ('IS701','IS501'), ('IS702','IS402'), ('IS702','IS503'), ('IS703','IS503'),
    ('IS703','IS406'), ('IS704','IS602'), ('IS706','IS604'),
    ('IS801','IS501'), ('IS802','IS502'), ('IS803','IS702'), ('IS805','IS706'),
    ('IS806','IS604')
) AS rel(curso, prereq)
JOIN unab.cursos c  ON c.codigo_curso  = rel.curso
JOIN unab.cursos pr ON pr.codigo_curso = rel.prereq
ON CONFLICT DO NOTHING;

-- ----------------------------------------------------------------------------
-- 4. Periodos académicos
-- ----------------------------------------------------------------------------
INSERT INTO unab.periodos_academicos (codigo, nombre, fecha_inicio, fecha_fin, activo) VALUES
('2025-2','Segundo semestre 2025','2025-07-21','2025-11-28', FALSE),
('2026-1','Primer semestre 2026', '2026-01-19','2026-05-29', TRUE),
('2026-2','Segundo semestre 2026','2026-07-20','2026-11-27', FALSE)
ON CONFLICT (codigo) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 5. Estudiantes sintéticos (30) — todos de Ingeniería de Sistemas
--    El semestre_actual es coherente con la fecha de ingreso.
-- ----------------------------------------------------------------------------
INSERT INTO unab.estudiantes
    (id_estudiante, documento, nombre, apellido, email, telefono, id_programa, semestre_actual, fecha_ingreso, estado)
SELECT v.id_est, v.doc, v.nombre, v.apellido, v.email, v.tel, p.id_programa, v.semestre, v.ingreso::DATE, 'activo'
FROM (VALUES
    ('10045231','1098765431','Laura',     'Martínez',  'l.martinez@unab.edu.co', '3101110001', 9, '2022-01-17'),
    ('10045232','1098765432','Carlos',    'Rodríguez', 'c.rodriguez@unab.edu.co','3101110002', 7, '2023-01-16'),
    ('10045233','1098765433','Ana',       'López',     'a.lopez@unab.edu.co',    '3101110003', 5, '2024-01-15'),
    ('10045234','1098765434','Jhon',      'García',    'j.garcia@unab.edu.co',   '3101110004', 3, '2025-01-20'),
    ('10045235','1098765435','María',     'Hernández', 'm.hernandez@unab.edu.co','3101110005', 1, '2026-01-19'),
    ('10045236','1098765436','Luis',      'Torres',    'l.torres@unab.edu.co',   '3101110006', 10,'2021-07-19'),
    ('10045237','1098765437','Sofía',     'Ramírez',   's.ramirez@unab.edu.co',  '3101110007', 8, '2022-07-18'),
    ('10045238','1098765438','Diego',     'Vargas',    'd.vargas@unab.edu.co',   '3101110008', 6, '2023-07-17'),
    ('10045239','1098765439','Valentina', 'Castro',    'v.castro@unab.edu.co',   '3101110009', 4, '2024-07-15'),
    ('10045240','1098765440','Andrés',    'Morales',   'a.morales@unab.edu.co',  '3101110010', 2, '2025-07-21'),
    ('10045241','1098765441','Camila',    'Jiménez',   'c.jimenez@unab.edu.co',  '3101110011', 9, '2022-01-17'),
    ('10045242','1098765442','Sebastián', 'Díaz',      's.diaz@unab.edu.co',     '3101110012', 7, '2023-01-16'),
    ('10045243','1098765443','Isabella',  'Reyes',     'i.reyes@unab.edu.co',    '3101110013', 5, '2024-01-15'),
    ('10045244','1098765444','Felipe',    'Gómez',     'f.gomez@unab.edu.co',    '3101110014', 3, '2025-01-20'),
    ('10045245','1098765445','Natalia',   'Sánchez',   'n.sanchez@unab.edu.co',  '3101110015', 1, '2026-01-19'),
    ('10045246','1098765446','Mateo',     'Pérez',     'm.perez@unab.edu.co',    '3101110016', 10,'2021-07-19'),
    ('10045247','1098765447','Luciana',   'Flores',    'l.flores@unab.edu.co',   '3101110017', 8, '2022-07-18'),
    ('10045248','1098765448','Santiago',  'Ruiz',      's.ruiz@unab.edu.co',     '3101110018', 6, '2023-07-17'),
    ('10045249','1098765449','Daniela',   'Núñez',     'd.nunez@unab.edu.co',    '3101110019', 4, '2024-07-15'),
    ('10045250','1098765450','Nicolás',   'Medina',    'n.medina@unab.edu.co',   '3101110020', 2, '2025-07-21'),
    ('10045251','1098765451','Gabriela',  'Ortega',    'g.ortega@unab.edu.co',   '3101110021', 9, '2022-01-17'),
    ('10045252','1098765452','Alejandro', 'Aguilar',   'a.aguilar@unab.edu.co',  '3101110022', 7, '2023-01-16'),
    ('10045253','1098765453','Mariana',   'Mendoza',   'm.mendoza@unab.edu.co',  '3101110023', 5, '2024-01-15'),
    ('10045254','1098765454','Ricardo',   'Guerrero',  'r.guerrero@unab.edu.co', '3101110024', 3, '2025-01-20'),
    ('10045255','1098765455','Paulina',   'Ríos',      'p.rios@unab.edu.co',     '3101110025', 1, '2026-01-19'),
    ('10045256','1098765456','Esteban',   'Delgado',   'e.delgado@unab.edu.co',  '3101110026', 10,'2021-07-19'),
    ('10045257','1098765457','Juanita',   'Vega',      'j.vega@unab.edu.co',     '3101110027', 8, '2022-07-18'),
    ('10045258','1098765458','Tomás',     'Rojas',     't.rojas@unab.edu.co',    '3101110028', 6, '2023-07-17'),
    ('10045259','1098765459','Manuela',   'Herrera',   'm.herrera@unab.edu.co',  '3101110029', 4, '2024-07-15'),
    ('10045260','1098765460','Simón',     'Molina',    's.molina@unab.edu.co',   '3101110030', 2, '2025-07-21')
) AS v(id_est, doc, nombre, apellido, email, tel, semestre, ingreso)
JOIN unab.programas p ON p.codigo = 'ING-SIS'
ON CONFLICT (id_estudiante) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6. Historial académico generado
--    Regla: los cursos con semestre_sugerido < semestre_actual ya se cursaron
--    y se aprueban. Las reprobaciones se aplican en el paso 6.1 para no
--    romper la cadena de prerrequisitos.
-- ----------------------------------------------------------------------------
INSERT INTO unab.historial_academico
    (id_estudiante, id_curso, periodo, nota, estado, creditos, intento, fecha_matricula, fecha_cierre)
SELECT
    e.id_estudiante,
    c.id_curso,
    unab.periodo_por_semestre(e.fecha_ingreso, c.semestre_sugerido),
    3.0 + (ABS(hashtext(e.id_estudiante || c.codigo_curso)::BIGINT) % 21) / 10.0,
    'aprobado',
    c.creditos,
    1,
    e.fecha_ingreso + ((c.semestre_sugerido - 1) * INTERVAL '6 months'),
    e.fecha_ingreso + ((c.semestre_sugerido - 1) * INTERVAL '6 months') + INTERVAL '4 months'
FROM unab.estudiantes e
JOIN unab.cursos c
  ON c.id_programa = e.id_programa
 AND c.semestre_sugerido < e.semestre_actual
ON CONFLICT (id_estudiante, id_curso, periodo) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 6.1 Reprobaciones controladas (~35% de los estudiantes)
--     Solo se reprueba un curso cuyos dependientes estén en el semestre
--     actual o en semestres futuros. Así el historial queda consistente y
--     las vistas de prerrequisitos producen alertas reales.
-- ----------------------------------------------------------------------------
WITH elegibles AS (
    SELECT
        e.id_estudiante,
        c.id_curso,
        ROW_NUMBER() OVER (
            PARTITION BY e.id_estudiante
            ORDER BY c.semestre_sugerido DESC, c.codigo_curso
        ) AS rn
    FROM unab.estudiantes e
    JOIN unab.cursos c ON c.id_programa = e.id_programa
    WHERE c.semestre_sugerido < e.semestre_actual
      AND ABS(hashtext(e.id_estudiante || 'falla' || c.codigo_curso)::BIGINT) % 100 < 35
      AND NOT EXISTS (
          SELECT 1
          FROM unab.prerrequisitos r
          JOIN unab.cursos d ON d.id_curso = r.id_curso
          WHERE r.id_prerrequisito = c.id_curso
            AND d.semestre_sugerido < e.semestre_actual
      )
)
UPDATE unab.historial_academico h
SET estado = 'reprobado',
    nota   = 2.0 + (ABS(hashtext(h.id_estudiante || h.id_curso::TEXT || 'nota')::BIGINT) % 10) / 10.0
FROM elegibles el
WHERE el.rn = 1
  AND h.id_estudiante = el.id_estudiante
  AND h.id_curso = el.id_curso;

-- Cursos del semestre actual -> en curso
INSERT INTO unab.historial_academico
    (id_estudiante, id_curso, periodo, nota, estado, creditos, intento, fecha_matricula)
SELECT
    e.id_estudiante,
    c.id_curso,
    '2026-1',
    NULL,
    'en_curso',
    c.creditos,
    1,
    '2026-01-19'
FROM unab.estudiantes e
JOIN unab.cursos c
  ON c.id_programa = e.id_programa
 AND c.semestre_sugerido = e.semestre_actual
ON CONFLICT (id_estudiante, id_curso, periodo) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 7. Caso de demo garantizado
--    Jhon García (10045234, semestre 3) reprueba Cálculo Integral (IS201):
--    Cálculo Multivariado (IS301) queda bloqueado y tampoco se matricula.
-- ----------------------------------------------------------------------------
UPDATE unab.historial_academico h
SET estado = 'aprobado', nota = 3.8
FROM unab.cursos c
WHERE c.id_curso = h.id_curso
  AND h.id_estudiante = '10045234'
  AND h.estado = 'reprobado'
  AND c.codigo_curso <> 'IS201';

UPDATE unab.historial_academico h
SET estado = 'reprobado', nota = 2.4
FROM unab.cursos c
WHERE c.id_curso = h.id_curso
  AND h.id_estudiante = '10045234'
  AND c.codigo_curso = 'IS201';

-- Jhon no pudo matricular Cálculo Multivariado (IS301) por el prerrequisito
-- reprobado: es el caso perfecto para demostrar la alerta en el chatbot.
DELETE FROM unab.historial_academico h
USING unab.cursos c
WHERE c.id_curso = h.id_curso
  AND h.id_estudiante = '10045234'
  AND h.estado = 'en_curso'
  AND c.codigo_curso = 'IS301';

-- ----------------------------------------------------------------------------
-- 8. Consolidar promedio y créditos aprobados en la tabla de estudiantes
-- ----------------------------------------------------------------------------
UPDATE unab.estudiantes e
SET creditos_aprobados = COALESCE(x.creditos, 0),
    promedio_acumulado = COALESCE(x.promedio, 0)
FROM (
    SELECT id_estudiante,
           SUM(creditos) FILTER (WHERE estado IN ('aprobado','homologado')) AS creditos,
           ROUND(AVG(nota) FILTER (WHERE estado IN ('aprobado','reprobado')), 2) AS promedio
    FROM unab.historial_academico
    GROUP BY id_estudiante
) x
WHERE x.id_estudiante = e.id_estudiante;

-- ----------------------------------------------------------------------------
-- 9. Calendario académico (ejemplo 2026-1)
-- ----------------------------------------------------------------------------
INSERT INTO unab.calendario_academico (id_periodo, evento, categoria, fecha_inicio, fecha_fin, descripcion)
SELECT pa.id_periodo, v.evento, v.categoria, v.inicio::DATE, v.fin::DATE, v.descripcion
FROM (VALUES
    ('2026-1','Inscripción de asignaturas 2026-1','matricula','2026-01-05','2026-01-16','Matrícula en línea por COSMOS.'),
    ('2026-1','Inicio de clases 2026-1','clases','2026-01-19','2026-01-19','Primer día de actividades académicas.'),
    ('2026-1','Fecha límite de adición y retiro','matricula','2026-01-30','2026-01-30','Último día para adicionar o retirar asignaturas.'),
    ('2026-1','Primer corte evaluativo','examenes','2026-03-09','2026-03-13','Semana de evaluaciones del primer corte.'),
    ('2026-1','Semana Santa','general','2026-03-30','2026-04-03','Receso institucional.'),
    ('2026-1','Segundo corte evaluativo','examenes','2026-04-20','2026-04-24','Semana de evaluaciones del segundo corte.'),
    ('2026-1','Último día de clases','clases','2026-05-15','2026-05-15','Finalización de actividades docentes.'),
    ('2026-1','Exámenes finales','examenes','2026-05-18','2026-05-29','Evaluaciones finales del semestre.'),
    ('2026-1','Publicación de notas','general','2026-06-05','2026-06-05','Consulta de calificaciones en COSMOS.'),
    ('2026-1','Ceremonia de grados','ceremonia','2026-06-20','2026-06-20','Grados de pregrado y posgrado.'),
    ('2026-1','Inscripción de asignaturas 2026-2','matricula','2026-06-22','2026-07-03','Matrícula para el segundo semestre.'),
    ('2026-1','Inicio de clases 2026-2','clases','2026-07-20','2026-07-20','Primer día del segundo semestre.'),
    ('2026-1','Pago de matrícula 2026-2','pagos','2026-06-22','2026-07-10','Plazo para el pago de matrícula.')
) AS v(periodo, evento, categoria, inicio, fin, descripcion)
JOIN unab.periodos_academicos pa ON pa.codigo = v.periodo
WHERE NOT EXISTS (
    SELECT 1 FROM unab.calendario_academico ca
    WHERE ca.evento = v.evento AND ca.fecha_inicio = v.inicio::DATE
);

-- ----------------------------------------------------------------------------
-- 10. Noticias / convocatorias de ejemplo
-- ----------------------------------------------------------------------------
INSERT INTO unab.noticias (titulo, resumen, contenido, url, fuente, categoria, fecha_publicacion)
VALUES
('Convocatoria de monitorías académicas 2026-1',
 'La UNAB abre la convocatoria para monitorías en Ingeniería de Sistemas.',
 'Los estudiantes con promedio superior a 4.0 pueden postularse como monitores académicos para el periodo 2026-1.',
 'https://www.unab.edu.co/noticias/monitorias-2026-1',
 'UNAB', 'convocatoria', '2026-01-10'),
('Beca de excelencia académica',
 'Postúlate a la beca de excelencia para el semestre 2026-1.',
 'La beca cubre hasta el 75% del valor de la matrícula para estudiantes con promedio sobresaliente.',
 'https://www.unab.edu.co/noticias/beca-excelencia-2026',
 'UNAB', 'beca', '2026-01-12'),
('Semana de la Ingeniería 2026',
 'Charlas, talleres y hackathon organizados por la Facultad de Ingeniería.',
 'Del 21 al 25 de abril se realizará la Semana de la Ingeniería con actividades abiertas para todos los estudiantes.',
 'https://www.unab.edu.co/noticias/semana-ingenieria-2026',
 'UNAB', 'evento', '2026-02-03'),
('Nuevos cursos de IA generativa',
 'El CCD lanza cursos de IA generativa para estudiantes de pregrado.',
 'Los cursos hacen parte de la Ruta de Competencias Digitales y no otorgan créditos académicos.',
 'https://www.unab.edu.co/noticias/cursos-ia-2026',
 'UNAB', 'curso', '2026-02-10'),
('Calendario de exámenes finales disponible',
 'Consulta las fechas de los exámenes finales del primer semestre 2026.',
 'Las fechas fueron publicadas en COSMOS y en la página oficial de la universidad.',
 'https://www.unab.edu.co/noticias/examenes-finales-2026-1',
 'UNAB', 'noticia', '2026-04-15'),
('Convocatoria de semilleros de investigación',
 'Inscripciones abiertas para los semilleros del programa de Ingeniería de Sistemas.',
 'Los semilleros de investigación reciben estudiantes desde segundo semestre.',
 'https://www.unab.edu.co/noticias/semilleros-2026',
 'UNAB', 'convocatoria', '2026-02-20')
ON CONFLICT (url) DO NOTHING;

-- ----------------------------------------------------------------------------
-- 11. Verificación rápida
-- ----------------------------------------------------------------------------
SELECT 'programas'      AS tabla, COUNT(*) AS registros FROM unab.programas
UNION ALL SELECT 'cursos',        COUNT(*) FROM unab.cursos
UNION ALL SELECT 'prerrequisitos',COUNT(*) FROM unab.prerrequisitos
UNION ALL SELECT 'estudiantes',   COUNT(*) FROM unab.estudiantes
UNION ALL SELECT 'historial',     COUNT(*) FROM unab.historial_academico
UNION ALL SELECT 'calendario',    COUNT(*) FROM unab.calendario_academico
UNION ALL SELECT 'noticias',      COUNT(*) FROM unab.noticias;

-- ============================================================================
-- FIN 02_seed.sql
-- ============================================================================
