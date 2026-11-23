-- ============================================================================
-- PROYECTO : Chatbot de Apoyo Académico UNAB
-- ARCHIVO  : 07_conocimiento_rag.sql
-- DESCRIPCIÓN:
--   Carga la base de conocimiento institucional del RAG (reglamento, FAQ,
--   bienestar, grado, becas y CCD). Inserta los chunks SIN embedding para que
--   el servidor MCP pueda usar la búsqueda por texto desde el primer momento.
--
--   Los embeddings se generan después con:
--       python rag/ingest.py --reembed
--   o desde el workflow WF01 de n8n.
--
--   Es idempotente: se puede ejecutar varias veces sin duplicar chunks.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Limpiar únicamente los chunks de estas fuentes (permite re-ejecutar)
-- ----------------------------------------------------------------------------
DELETE FROM unab.documentos_vectoriales
WHERE metadata->>'fuente' IN (
    'reglamento_estudiantil.md',
    'faq_academica.md',
    'proceso_grado.md',
    'becas_monitorias.md',
    'bienestar_universitario.md',
    'ccd_competencias_digitales.md'
);

-- ----------------------------------------------------------------------------
-- 2. Chunks de conocimiento
-- ----------------------------------------------------------------------------
INSERT INTO unab.documentos_vectoriales (content, metadata)
SELECT v.contenido, jsonb_build_object(
    'fuente',      v.fuente,
    'titulo',      v.titulo,
    'categoria',   v.categoria,
    'chunk',       v.orden,
    'actualizado', CURRENT_DATE
)
FROM (VALUES
    -- ------------------------------------------------------------------
    -- Reglamento estudiantil
    -- ------------------------------------------------------------------
    ('reglamento_estudiantil.md', 'Reglamento Estudiantil UNAB', 'reglamento', 1,
     'El Reglamento Estudiantil de la UNAB regula los derechos y deberes de los estudiantes de pregrado. Todo estudiante matriculado se compromete a cumplir los horarios, las normas académicas y el código de honor. Los derechos incluyen recibir docencia de calidad, conocer el programa de cada asignatura, solicitar revisión de notas y acceder a los servicios de bienestar universitario. Los deberes incluyen asistir a clase, respetar a la comunidad académica y realizar las evaluaciones con honestidad.'),

    ('reglamento_estudiantil.md', 'Reglamento Estudiantil UNAB', 'reglamento', 2,
     'La evaluación del aprendizaje se expresa en una escala de 0.0 a 5.0. La nota mínima aprobatoria es 3.0. Cada asignatura tiene al menos tres evaluaciones parciales y una evaluación final; el profesor informa las fechas y los porcentajes al inicio del semestre. Las notas se publican en COSMOS dentro de los cinco días hábiles siguientes a cada corte. Si un estudiante considera que una nota es incorrecta, puede solicitar revisión por escrito al profesor dentro de los tres días hábiles siguientes a la publicación.'),

    ('reglamento_estudiantil.md', 'Reglamento Estudiantil UNAB', 'reglamento', 3,
     'Una asignatura se considera reprobada cuando la nota final es inferior a 3.0. El estudiante debe matricularla nuevamente en un periodo posterior, pagando los créditos correspondientes. Una asignatura puede reprobarse hasta dos veces; en el tercer intento el caso pasa al Comité Académico del programa, que define un plan de acompañamiento. La reprobación afecta el promedio acumulado y puede bloquear asignaturas que tengan esa materia como prerrequisito.'),

    ('reglamento_estudiantil.md', 'Reglamento Estudiantil UNAB', 'reglamento', 4,
     'Los prerrequisitos son asignaturas que deben estar aprobadas antes de matricular otra. El sistema de matrícula valida automáticamente esta condición: si el prerrequisito está reprobado, pendiente o en curso, la asignatura aparece bloqueada. Para habilitarla es necesario aprobar primero el prerrequisito. Los correquisitos, en cambio, deben matricularse en el mismo periodo. La malla curricular de cada programa detalla las relaciones de prerrequisito y correquisito.'),

    ('reglamento_estudiantil.md', 'Reglamento Estudiantil UNAB', 'reglamento', 5,
     'El estudiante puede cancelar una o varias asignaturas hasta la fecha límite de cancelación publicada en el calendario académico. La cancelación no genera devolución del valor de la matrícula, pero evita que la asignatura quede como reprobada en el historial. Si la cancelación deja al estudiante con menos del 60% de los créditos matriculados, se considera retiro voluntario del semestre y requiere visto bueno de la dirección del programa.'),

    ('reglamento_estudiantil.md', 'Reglamento Estudiantil UNAB', 'reglamento', 6,
     'El promedio acumulado (PA) es el promedio ponderado por créditos de todas las asignaturas aprobadas y reprobadas del plan de estudios. Las asignaturas canceladas no se incluyen. El promedio semestral (PS) considera solo las asignaturas del periodo. Para conservar la condición de estudiante regular se requiere un promedio acumulado igual o superior a 3.0; por debajo de ese valor el estudiante entra en periodo de prueba académica y recibe acompañamiento del programa.'),

    -- ------------------------------------------------------------------
    -- FAQ académica
    -- ------------------------------------------------------------------
    ('faq_academica.md', 'Preguntas frecuentes académicas', 'faq', 1,
     '¿Cuántos créditos puedo matricular? El límite normal es de 18 a 20 créditos por semestre. Los estudiantes con promedio acumulado igual o superior a 4.0 pueden solicitar autorización para matricular hasta 22 créditos. Los estudiantes en periodo de prueba académica deben matricular entre 9 y 14 créditos, según la recomendación de su director de programa.'),

    ('faq_academica.md', 'Preguntas frecuentes académicas', 'faq', 2,
     '¿Cómo sé cuánto me falta para graduarme? El porcentaje de avance se calcula dividiendo los créditos aprobados entre los créditos totales del plan de estudios. La proyección de semestres restantes usa el ritmo real de créditos aprobados por semestre. Puedes consultar ambos indicadores en COSMOS, en la opción "Avance académico", o preguntarle al chatbot de apoyo académico de la UNAB.'),

    ('faq_academica.md', 'Preguntas frecuentes académicas', 'faq', 3,
     '¿Qué hago si pierdo una asignatura? Primero revisa con tu director de programa si la asignatura es prerrequisito de otras. Si lo es, deberás repetirla antes de avanzar en esa cadena. El chatbot puede mostrarte los cursos bloqueados y recomendarte una matrícula que respete los prerrequisitos y tu límite de créditos. Si la pérdida afecta tu promedio, solicita una cita con consejería académica de Bienestar Universitario.'),

    ('faq_academica.md', 'Preguntas frecuentes académicas', 'faq', 4,
     '¿Dónde consulto mis notas y mi horario? La plataforma oficial es COSMOS (cosmos.unab.edu.co). Allí encuentras notas por corte, historial académico, horario, recibo de matrícula y certificados. La app del chatbot de apoyo académico complementa a COSMOS: responde preguntas, explica el reglamento y ayuda a planear la matrícula, pero no reemplaza los trámites oficiales.'),

    ('faq_academica.md', 'Preguntas frecuentes académicas', 'faq', 5,
     '¿Cómo solicito un certificado de notas? Los certificados de notas y de estudio se solicitan en la Oficina de Registro Académico o en COSMOS, sección "Certificados". El certificado de notas incluye el historial completo con notas y créditos; el certificado de estudio indica el semestre que cursa y la condición de estudiante activo. La entrega puede ser virtual o presencial y tiene un costo administrativo.'),

    -- ------------------------------------------------------------------
    -- Proceso de grado
    -- ------------------------------------------------------------------
    ('proceso_grado.md', 'Requisitos y opciones de grado', 'grado', 1,
     'Para obtener el título de pregrado el estudiante debe aprobar el 100% de los créditos del plan de estudios, tener un promedio acumulado igual o superior a 3.0, cumplir las horas de práctica o trabajo de grado y estar a paz y salvo con la universidad. También debe acreditar el requisito de segunda lengua y las competencias digitales definidas por el CCD. La solicitud de grado se radica en Registro Académico durante el periodo indicado en el calendario.'),

    ('proceso_grado.md', 'Requisitos y opciones de grado', 'grado', 2,
     'Las opciones de grado de los programas de ingeniería son: trabajo de grado (investigación o desarrollo tecnológico), práctica profesional, seminario de profundización y emprendimiento. Cada opción tiene un número mínimo de créditos y un director asignado. El estudiante debe inscribir la opción en el semestre en que la va a desarrollar y presentar un anteproyecto aprobado por el Comité de Trabajos de Grado.'),

    ('proceso_grado.md', 'Requisitos y opciones de grado', 'grado', 3,
     'La ceremonia de grados se realiza dos veces al año, al finalizar cada semestre. Para participar, el estudiante debe haber radicado la solicitud de grado, entregado el paz y salvo y aprobado la sustentación pública de su trabajo de grado cuando aplique. La universidad publica la lista de graduandos y el protocolo de la ceremonia en la página oficial y en COSMOS.'),

    -- ------------------------------------------------------------------
    -- Becas y monitorías
    -- ------------------------------------------------------------------
    ('becas_monitorias.md', 'Becas, descuentos y monitorías', 'becas', 1,
     'La Beca de Excelencia Académica reconoce a los estudiantes con promedio acumulado sobresaliente. Cubre un porcentaje de la matrícula del semestre siguiente y se renueva cada periodo si el estudiante mantiene el promedio y no tiene sanciones disciplinarias. La convocatoria se publica al final de cada semestre en la página de la universidad y en COSMOS.'),

    ('becas_monitorias.md', 'Becas, descuentos y monitorías', 'becas', 2,
     'Las monitorías académicas son apoyos económicos para estudiantes con buen rendimiento que acompañan a sus compañeros en asignaturas de alta complejidad. Requieren promedio igual o superior a 4.0, haber aprobado la asignatura y disponer de al menos 12 horas semanales. La postulación se hace al inicio de cada semestre ante la facultad correspondiente.'),

    ('becas_monitorias.md', 'Becas, descuentos y monitorías', 'becas', 3,
     'Existen además descuentos por hermanos, egresados, convenios empresariales y población vulnerable. Cada beneficio tiene requisitos y fechas de solicitud propias. Los descuentos no son acumulables entre sí y deben solicitarse antes del pago de la matrícula. La Oficina de Admisiones y Registro revisa cada caso y comunica la decisión por correo institucional.'),

    -- ------------------------------------------------------------------
    -- Bienestar universitario
    -- ------------------------------------------------------------------
    ('bienestar_universitario.md', 'Bienestar Universitario', 'bienestar', 1,
     'Bienestar Universitario ofrece acompañamiento psicológico, orientación vocacional, trabajo social, deporte, cultura y promoción de la salud. Los servicios son gratuitos para estudiantes matriculados y se solicitan de forma presencial o por el correo de bienestar. Las citas de consejería son confidenciales y no quedan registradas en la hoja de vida académica.'),

    ('bienestar_universitario.md', 'Bienestar Universitario', 'bienestar', 2,
     'Si un estudiante presenta dificultades académicas, emocionales o económicas que afecten su rendimiento, puede solicitar una cita de consejería académica. El equipo de Bienestar y el director de programa construyen un plan de acompañamiento que puede incluir tutorías, ajuste de carga académica o remisión a servicios especializados. Solicitar apoyo no tiene ninguna consecuencia disciplinaria.'),

    -- ------------------------------------------------------------------
    -- CCD / competencias digitales
    -- ------------------------------------------------------------------
    ('ccd_competencias_digitales.md', 'Centro de Competencias Digitales (CCD)', 'ccd', 1,
     'El Centro de Competencias Digitales (CCD) de la UNAB acompaña la formación en habilidades digitales de estudiantes y profesores. Su Ruta de Competencias Digitales organiza cursos y microcredenciales en cinco áreas: alfabetización digital, comunicación y colaboración, creación de contenido, seguridad y uso responsable de la inteligencia artificial.'),

    ('ccd_competencias_digitales.md', 'Centro de Competencias Digitales (CCD)', 'ccd', 2,
     'La Ruta de Competencias Digitales es flexible y no otorga créditos académicos. Los estudiantes avanzan a su ritmo, presentan evaluaciones cortas y reciben una insignia digital por cada nivel completado. Completar la ruta es un requisito de competencias digitales para el grado en varios programas y se puede consultar en el portal del CCD.'),

    ('ccd_competencias_digitales.md', 'Centro de Competencias Digitales (CCD)', 'ccd', 3,
     'El CCD promueve el uso responsable de la inteligencia artificial generativa. Está permitido usar asistentes de IA como apoyo para estudiar, resumir o generar ideas, siempre que se declaren las herramientas usadas y se respete la autoría del trabajo. No está permitido presentar texto generado por IA como propio ni usarlo para resolver evaluaciones sin autorización del profesor.'),

    ('ccd_competencias_digitales.md', 'Centro de Competencias Digitales (CCD)', 'ccd', 4,
     'El chatbot de apoyo académico de la UNAB es un proyecto desarrollado con el CCD. Usa recuperación aumentada con generación (RAG) sobre documentos institucionales y herramientas MCP para consultar el historial académico, el calendario y las noticias. Responde en español, cita sus fuentes cuando es posible y no reemplaza la asesoría de un profesor o de Registro Académico.')
) AS v(fuente, titulo, categoria, orden, contenido);

-- ----------------------------------------------------------------------------
-- 3. Catálogo de documentos (metadatos de control de ingesta)
-- ----------------------------------------------------------------------------
INSERT INTO unab.documentos (titulo, fuente, tipo, categoria, version, num_chunks, procesado)
SELECT
    MAX(metadata->>'titulo'),
    metadata->>'fuente',
    'markdown',
    MAX(metadata->>'categoria'),
    '1.0',
    COUNT(*),
    FALSE
FROM unab.documentos_vectoriales
WHERE metadata->>'fuente' IN (
    'reglamento_estudiantil.md',
    'faq_academica.md',
    'proceso_grado.md',
    'becas_monitorias.md',
    'bienestar_universitario.md',
    'ccd_competencias_digitales.md'
)
GROUP BY metadata->>'fuente'
ON CONFLICT (fuente) DO UPDATE
SET titulo     = EXCLUDED.titulo,
    categoria  = EXCLUDED.categoria,
    num_chunks = EXCLUDED.num_chunks,
    procesado  = FALSE,
    updated_at = NOW();

-- ----------------------------------------------------------------------------
-- 4. Verificación
-- ----------------------------------------------------------------------------
SELECT 'documentos' AS tabla, COUNT(*) AS registros FROM unab.documentos
UNION ALL
SELECT 'chunks', COUNT(*) FROM unab.documentos_vectoriales;

-- ============================================================================
-- FIN 07_conocimiento_rag.sql
-- ============================================================================
