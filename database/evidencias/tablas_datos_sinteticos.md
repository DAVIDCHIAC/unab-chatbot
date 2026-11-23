# Tablas y datos de demostración

> Volcado real del esquema `unab` en Supabase. **Todos los datos son sintéticos.**
> Para verlos en vivo: Supabase Dashboard → *Table Editor* → esquema `unab`.

## Tablas

| Tabla | Filas |
|---|---:|
| `unab.calendario_academico` | 26 |
| `unab.conversaciones` | 61 |
| `unab.cursos` | 51 |
| `unab.dispositivos` | 0 |
| `unab.documentos` | 7 |
| `unab.documentos_vectoriales` | 27 |
| `unab.estudiantes` | 30 |
| `unab.historial_academico` | 908 |
| `unab.noticias` | 21 |
| `unab.notificaciones` | 0 |
| `unab.periodos_academicos` | 3 |
| `unab.prerrequisitos` | 37 |
| `unab.programas` | 12 |
| `unab.solicitudes` | 0 |

## Vistas

| Vista | Filas |
|---|---:|
| `unab.v_alertas_academicas` | 30 |
| `unab.v_avance_plan` | 30 |
| `unab.v_calendario_proximo` | 13 |
| `unab.v_cursos_pendientes` | 648 |
| `unab.v_estado_estudiante` | 30 |
| `unab.v_historial_detalle` | 908 |
| `unab.v_kpis_chatbot` | 1 |
| `unab.v_malla_curricular` | 51 |
| `unab.v_noticias_recientes` | 21 |
| `unab.v_prerrequisitos_pendientes` | 82 |
| `unab.v_proyeccion_semestres` | 30 |

## `unab.programas` (12 filas)

| id_programa | codigo | nombre | facultad | nivel | creditos_totales | semestres_totales | activo | created_at |
|---|---|---|---|---|---|---|---|---|
| 1 | ING-SIS | Ingeniería de Sistemas | Facultad de Ingeniería | pregrado | 160 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |
| 2 | ING-IND | Ingeniería Industrial | Facultad de Ingeniería | pregrado | 170 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |
| 3 | ING-ELE | Ingeniería Electrónica | Facultad de Ingeniería | pregrado | 168 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |
| 4 | ING-MEC | Ingeniería Mecatrónica | Facultad de Ingeniería | pregrado | 172 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |
| 5 | ADM-EMP | Administración de Empresas | Ciencias Económicas | pregrado | 155 | 9 | True | 2026-11-18 17:44:38.424741+00:00 |
| 6 | CONT | Contaduría Pública | Ciencias Económicas | pregrado | 158 | 9 | True | 2026-11-18 17:44:38.424741+00:00 |
| 7 | DER | Derecho | Ciencias Jurídicas | pregrado | 165 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |
| 8 | PSI | Psicología | Ciencias de la Salud | pregrado | 168 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |
| 9 | MED | Medicina | Ciencias de la Salud | pregrado | 240 | 12 | True | 2026-11-18 17:44:38.424741+00:00 |
| 10 | COM-SOC | Comunicación Social | Ciencias Sociales | pregrado | 152 | 9 | True | 2026-11-18 17:44:38.424741+00:00 |
| 11 | DIS-GRA | Diseño Gráfico | Ciencias Sociales | pregrado | 150 | 9 | True | 2026-11-18 17:44:38.424741+00:00 |
| 12 | ARQ | Arquitectura | Arquitectura | pregrado | 180 | 10 | True | 2026-11-18 17:44:38.424741+00:00 |

## `unab.periodos_academicos` (3 filas)

| id_periodo | codigo | nombre | fecha_inicio | fecha_fin | activo |
|---|---|---|---|---|---|
| 1 | 2025-2 | Segundo semestre 2025 | 2025-07-21 | 2025-11-28 | False |
| 2 | 2026-1 | Primer semestre 2026 | 2026-01-19 | 2026-05-29 | False |
| 3 | 2026-2 | Segundo semestre 2026 | 2026-07-15 | 2026-11-30 | True |

## `unab.cursos` (51 filas)

| id_curso | id_programa | codigo_curso | nombre | creditos | semestre_sugerido | tipo | area | horas_teoria | horas_practica | descripcion | activo |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 1 | IS101 | Cálculo Diferencial | 4 | 1 | obligatorio | Ciencias Básicas | 4 | 0 | Límites, derivadas y aplicaciones. | True |
| 2 | 1 | IS102 | Álgebra Lineal | 3 | 1 | obligatorio | Ciencias Básicas | 3 | 0 | Matrices, sistemas de ecuaciones y espacios vectoriales. | True |
| 3 | 1 | IS103 | Introducción a la Ingeniería de Sistemas | 2 | 1 | obligatorio | Ingeniería Aplicada | 2 | 0 | Rol profesional y campos de acción. | True |
| 4 | 1 | IS104 | Programación I | 4 | 1 | obligatorio | Software | 2 | 4 | Fundamentos de programación y pensamiento algorítmico. | True |
| 5 | 1 | IS105 | Competencias Comunicativas | 2 | 1 | transversal | Humanidades | 2 | 0 | Comunicación oral y escrita académica. | True |
| 6 | 1 | IS106 | Cátedra UNAB | 1 | 1 | transversal | Humanidades | 1 | 0 | Identidad y vida universitaria. | True |
| 7 | 1 | IS201 | Cálculo Integral | 4 | 2 | obligatorio | Ciencias Básicas | 4 | 0 | Integrales y aplicaciones. | True |
| 8 | 1 | IS202 | Física I | 4 | 2 | obligatorio | Ciencias Básicas | 3 | 2 | Mecánica clásica. | True |
| 9 | 1 | IS203 | Programación II | 4 | 2 | obligatorio | Software | 2 | 4 | Programación orientada a objetos. | True |
| 10 | 1 | IS204 | Estructuras Discretas | 3 | 2 | obligatorio | Ciencias Básicas | 3 | 0 | Lógica, conjuntos, grafos y combinatoria. | True |
| 11 | 1 | IS205 | Estadística Descriptiva | 3 | 2 | obligatorio | Ciencias Básicas | 3 | 0 | Organización y análisis de datos. | True |
| 12 | 1 | IS301 | Cálculo Multivariado | 4 | 3 | obligatorio | Ciencias Básicas | 4 | 0 | Funciones de varias variables. | True |
| 13 | 1 | IS302 | Física II | 4 | 3 | obligatorio | Ciencias Básicas | 3 | 2 | Electricidad y magnetismo. | True |
| 14 | 1 | IS303 | Estructuras de Datos | 4 | 3 | obligatorio | Software | 2 | 4 | Listas, árboles, grafos y complejidad. | True |
| 15 | 1 | IS304 | Bases de Datos I | 3 | 3 | obligatorio | Datos | 2 | 2 | Modelo relacional y SQL. | True |
| 16 | 1 | IS305 | Arquitectura de Computadores | 3 | 3 | obligatorio | Infraestructura | 2 | 2 | Organización del hardware. | True |
| 17 | 1 | IS401 | Ecuaciones Diferenciales | 3 | 4 | obligatorio | Ciencias Básicas | 3 | 0 | EDO y aplicaciones en ingeniería. | True |
| 18 | 1 | IS402 | Bases de Datos II | 3 | 4 | obligatorio | Datos | 2 | 2 | Normalización, transacciones e índices. | True |
| 19 | 1 | IS403 | Análisis de Algoritmos | 3 | 4 | obligatorio | Software | 3 | 0 | Complejidad y diseño de algoritmos. | True |
| 20 | 1 | IS404 | Sistemas Operativos | 3 | 4 | obligatorio | Infraestructura | 2 | 2 | Procesos, memoria y concurrencia. | True |
| 21 | 1 | IS405 | Ingeniería de Software I | 3 | 4 | obligatorio | Software | 2 | 2 | Requisitos y modelado. | True |
| 22 | 1 | IS406 | Probabilidad y Estadística | 3 | 4 | obligatorio | Ciencias Básicas | 3 | 0 | Variables aleatorias e inferencia. | True |
| 23 | 1 | IS501 | Redes de Computadores | 3 | 5 | obligatorio | Infraestructura | 2 | 2 | Modelo TCP/IP y enrutamiento. | True |
| 24 | 1 | IS502 | Ingeniería de Software II | 3 | 5 | obligatorio | Software | 2 | 2 | Diseño, arquitectura y pruebas. | True |
| 25 | 1 | IS503 | Inteligencia Artificial | 3 | 5 | obligatorio | Inteligencia Artificial | 2 | 2 | Búsqueda, agentes y aprendizaje. | True |
| 26 | 1 | IS504 | Teoría de Lenguajes y Autómatas | 3 | 5 | obligatorio | Ciencias Básicas | 3 | 0 | Autómatas y gramáticas. | True |
| 27 | 1 | IS505 | Investigación de Operaciones | 3 | 5 | obligatorio | Ciencias Básicas | 3 | 0 | Optimización y modelos. | True |
| 28 | 1 | IS506 | Electiva Profesional I | 3 | 5 | electivo | Electivas | 3 | 0 | Curso electivo de profundización. | True |
| 29 | 1 | IS601 | Seguridad Informática | 3 | 6 | obligatorio | Infraestructura | 2 | 2 | Criptografía y seguridad de sistemas. | True |
| 30 | 1 | IS602 | Arquitectura de Software | 3 | 6 | obligatorio | Software | 2 | 2 | Patrones y estilos arquitectónicos. | True |
| 31 | 1 | IS603 | Compiladores | 3 | 6 | obligatorio | Software | 2 | 2 | Análisis léxico, sintáctico y semántico. | True |
| 32 | 1 | IS604 | Gestión de Proyectos TI | 3 | 6 | obligatorio | Gestión | 2 | 2 | PMBOK, ágil y Scrum. | True |
| 33 | 1 | IS605 | Electiva Profesional II | 3 | 6 | electivo | Electivas | 3 | 0 | Curso electivo de profundización. | True |
| 34 | 1 | IS606 | Ética Profesional | 2 | 6 | transversal | Humanidades | 2 | 0 | Ética y responsabilidad profesional. | True |
| 35 | 1 | IS701 | Computación en la Nube | 3 | 7 | obligatorio | Infraestructura | 2 | 2 | IaaS, PaaS, SaaS y despliegue. | True |
| 36 | 1 | IS702 | Big Data | 3 | 7 | obligatorio | Datos | 2 | 2 | Procesamiento distribuido de datos. | True |
| 37 | 1 | IS703 | Machine Learning | 3 | 7 | obligatorio | Inteligencia Artificial | 2 | 2 | Modelos supervisados y no supervisados. | True |
| 38 | 1 | IS704 | DevOps y Automatización | 3 | 7 | obligatorio | Software | 2 | 2 | CI/CD, contenedores y observabilidad. | True |
| 39 | 1 | IS705 | Electiva Profesional III | 3 | 7 | electivo | Electivas | 3 | 0 | Curso electivo de profundización. | True |
| 40 | 1 | IS706 | Trabajo de Grado I | 2 | 7 | obligatorio | Investigación | 1 | 2 | Formulación del proyecto de grado. | True |
| 41 | 1 | IS801 | Internet de las Cosas | 3 | 8 | obligatorio | Infraestructura | 2 | 2 | Sensores, protocolos y edge computing. | True |
| 42 | 1 | IS802 | Desarrollo de Aplicaciones Móviles | 3 | 8 | obligatorio | Software | 2 | 2 | Android/Kotlin y consumo de APIs. | True |
| 43 | 1 | IS803 | Analítica de Datos | 3 | 8 | obligatorio | Datos | 2 | 2 | Visualización y dashboards. | True |
| 44 | 1 | IS804 | Electiva Profesional IV | 3 | 8 | electivo | Electivas | 3 | 0 | Curso electivo de profundización. | True |
| 45 | 1 | IS805 | Trabajo de Grado II | 3 | 8 | obligatorio | Investigación | 1 | 4 | Ejecución y sustentación. | True |
| 46 | 1 | IS806 | Práctica Profesional | 6 | 8 | obligatorio | Práctica | 0 | 12 | Práctica en empresa. | True |
| 47 | 1 | IS901 | Emprendimiento e Innovación | 3 | 9 | obligatorio | Gestión | 2 | 2 | Modelos de negocio y innovación. | True |
| 48 | 1 | IS902 | Electiva Profesional V | 3 | 9 | electivo | Electivas | 3 | 0 | Curso electivo de profundización. | True |
| 49 | 1 | IS903 | Seminario de Investigación | 2 | 9 | obligatorio | Investigación | 2 | 0 | Seminario de actualización. | True |
| 50 | 1 | IS1001 | Opción de Grado | 6 | 10 | obligatorio | Investigación | 0 | 12 | Modalidad de grado. | True |
| 51 | 1 | IS1002 | Electiva Profesional VI | 3 | 10 | electivo | Electivas | 3 | 0 | Curso electivo de profundización. | True |

## `unab.prerrequisitos` (37 filas)

| id_curso | id_prerrequisito | tipo |
|---|---|---|
| 8 | 1 | prerrequisito |
| 7 | 1 | prerrequisito |
| 10 | 2 | prerrequisito |
| 9 | 4 | prerrequisito |
| 12 | 7 | prerrequisito |
| 13 | 8 | prerrequisito |
| 16 | 9 | prerrequisito |
| 15 | 9 | prerrequisito |
| 14 | 9 | prerrequisito |
| 26 | 10 | prerrequisito |
| 14 | 10 | prerrequisito |
| 22 | 11 | prerrequisito |
| 17 | 12 | prerrequisito |
| 21 | 14 | prerrequisito |
| 19 | 14 | prerrequisito |
| 18 | 15 | prerrequisito |
| 23 | 16 | prerrequisito |
| 20 | 16 | prerrequisito |
| 27 | 17 | prerrequisito |
| 36 | 18 | prerrequisito |
| 25 | 19 | prerrequisito |
| 24 | 21 | prerrequisito |
| 37 | 22 | prerrequisito |
| 41 | 23 | prerrequisito |
| 35 | 23 | prerrequisito |
| 29 | 23 | prerrequisito |
| 42 | 24 | prerrequisito |
| 32 | 24 | prerrequisito |
| 30 | 24 | prerrequisito |
| 37 | 25 | prerrequisito |
| 36 | 25 | prerrequisito |
| 31 | 26 | prerrequisito |
| 38 | 30 | prerrequisito |
| 46 | 32 | prerrequisito |
| 40 | 32 | prerrequisito |
| 43 | 36 | prerrequisito |
| 45 | 40 | prerrequisito |

## `unab.estudiantes` (30 filas)

| id_estudiante | documento | nombre | apellido | email | telefono | id_programa | semestre_actual | fecha_ingreso | estado | promedio_acumulado | creditos_aprobados | user_id | created_at | updated_at |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 10045234 | 1098765434 | Jhon | García | j.garcia@unab.edu.co | 3101110004 | 1 | 3 | 2025-01-20 | activo | 3.69 | 30 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045243 | 1098765443 | Isabella | Reyes | i.reyes@unab.edu.co | 3101110013 | 1 | 5 | 2024-01-15 | activo | 3.92 | 67 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045260 | 1098765460 | Simón | Molina | s.molina@unab.edu.co | 3101110030 | 1 | 2 | 2025-07-21 | activo | 3.87 | 16 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045242 | 1098765442 | Sebastián | Díaz | s.diaz@unab.edu.co | 3101110012 | 1 | 7 | 2023-01-16 | activo | 3.91 | 102 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045240 | 1098765440 | Andrés | Morales | a.morales@unab.edu.co | 3101110010 | 1 | 2 | 2025-07-21 | activo | 3.65 | 12 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045231 | 1098765431 | Laura | Martínez | l.martinez@unab.edu.co | 3101110001 | 1 | 9 | 2022-01-17 | activo | 3.92 | 140 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045238 | 1098765438 | Diego | Vargas | d.vargas@unab.edu.co | 3101110008 | 1 | 6 | 2023-07-17 | activo | 4.05 | 85 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045256 | 1098765456 | Esteban | Delgado | e.delgado@unab.edu.co | 3101110026 | 1 | 10 | 2021-07-19 | activo | 4.01 | 148 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045244 | 1098765444 | Felipe | Gómez | f.gomez@unab.edu.co | 3101110014 | 1 | 3 | 2025-01-20 | activo | 3.94 | 33 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045248 | 1098765448 | Santiago | Ruiz | s.ruiz@unab.edu.co | 3101110018 | 1 | 6 | 2023-07-17 | activo | 3.96 | 85 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045241 | 1098765441 | Camila | Jiménez | c.jimenez@unab.edu.co | 3101110011 | 1 | 9 | 2022-01-17 | activo | 3.84 | 140 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045247 | 1098765447 | Luciana | Flores | l.flores@unab.edu.co | 3101110017 | 1 | 8 | 2022-07-18 | activo | 4.01 | 119 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045254 | 1098765454 | Ricardo | Guerrero | r.guerrero@unab.edu.co | 3101110024 | 1 | 3 | 2025-01-20 | activo | 3.95 | 30 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045251 | 1098765451 | Gabriela | Ortega | g.ortega@unab.edu.co | 3101110021 | 1 | 9 | 2022-01-17 | activo | 4.16 | 140 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045259 | 1098765459 | Manuela | Herrera | m.herrera@unab.edu.co | 3101110029 | 1 | 4 | 2024-07-15 | activo | 4.01 | 48 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045237 | 1098765437 | Sofía | Ramírez | s.ramirez@unab.edu.co | 3101110007 | 1 | 8 | 2022-07-18 | activo | 3.95 | 119 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045239 | 1098765439 | Valentina | Castro | v.castro@unab.edu.co | 3101110009 | 1 | 4 | 2024-07-15 | activo | 3.84 | 48 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045258 | 1098765458 | Tomás | Rojas | t.rojas@unab.edu.co | 3101110028 | 1 | 6 | 2023-07-17 | activo | 3.95 | 85 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045236 | 1098765436 | Luis | Torres | l.torres@unab.edu.co | 3101110006 | 1 | 10 | 2021-07-19 | activo | 3.94 | 148 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045245 | 1098765445 | Natalia | Sánchez | n.sanchez@unab.edu.co | 3101110015 | 1 | 1 | 2026-01-19 | activo | 0.00 | 0 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045255 | 1098765455 | Paulina | Ríos | p.rios@unab.edu.co | 3101110025 | 1 | 1 | 2026-01-19 | activo | 0.00 | 0 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045252 | 1098765452 | Alejandro | Aguilar | a.aguilar@unab.edu.co | 3101110022 | 1 | 7 | 2023-01-16 | activo | 3.84 | 102 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045257 | 1098765457 | Juanita | Vega | j.vega@unab.edu.co | 3101110027 | 1 | 8 | 2022-07-18 | activo | 4.10 | 119 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045250 | 1098765450 | Nicolás | Medina | n.medina@unab.edu.co | 3101110020 | 1 | 2 | 2025-07-21 | activo | 3.98 | 14 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045246 | 1098765446 | Mateo | Pérez | m.perez@unab.edu.co | 3101110016 | 1 | 10 | 2021-07-19 | activo | 3.90 | 148 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045253 | 1098765453 | Mariana | Mendoza | m.mendoza@unab.edu.co | 3101110023 | 1 | 5 | 2024-01-15 | activo | 3.94 | 67 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045232 | 1098765432 | Carlos | Rodríguez | c.rodriguez@unab.edu.co | 3101110002 | 1 | 7 | 2023-01-16 | activo | 3.94 | 102 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045249 | 1098765449 | Daniela | Núñez | d.nunez@unab.edu.co | 3101110019 | 1 | 4 | 2024-07-15 | activo | 3.94 | 49 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045233 | 1098765433 | Ana | López | a.lopez@unab.edu.co | 3101110003 | 1 | 5 | 2024-01-15 | activo | 3.77 | 67 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |
| 10045235 | 1098765435 | María | Hernández | m.hernandez@unab.edu.co | 3101110005 | 1 | 1 | 2026-01-19 | activo | 0.00 | 0 |  | 2026-11-18 17:44:38.424741+00:00 | 2026-11-18 17:44:38.424741+00:00 |

## `unab.calendario_academico` (26 filas)

| id | id_periodo | evento | categoria | fecha_inicio | fecha_fin | descripcion | publico | fuente | updated_at |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 2 | Pago de matrícula 2026-2 | pagos | 2026-06-22 | 2026-07-10 | Plazo para el pago de matrícula. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 2 | 2 | Publicación de notas | general | 2026-06-05 | 2026-06-05 | Consulta de calificaciones en COSMOS. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 3 | 2 | Fecha límite de adición y retiro | matricula | 2026-01-30 | 2026-01-30 | Último día para adicionar o retirar asignaturas. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 4 | 2 | Inscripción de asignaturas 2026-2 | matricula | 2026-06-22 | 2026-07-03 | Matrícula para el segundo semestre. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 5 | 2 | Semana Santa | general | 2026-03-30 | 2026-04-03 | Receso institucional. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 6 | 2 | Inicio de clases 2026-2 | clases | 2026-07-20 | 2026-07-20 | Primer día del segundo semestre. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 7 | 2 | Último día de clases | clases | 2026-05-15 | 2026-05-15 | Finalización de actividades docentes. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 8 | 2 | Inscripción de asignaturas 2026-1 | matricula | 2026-01-05 | 2026-01-16 | Matrícula en línea por COSMOS. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 9 | 2 | Segundo corte evaluativo | examenes | 2026-04-20 | 2026-04-24 | Semana de evaluaciones del segundo corte. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 10 | 2 | Exámenes finales | examenes | 2026-05-18 | 2026-05-29 | Evaluaciones finales del semestre. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 11 | 2 | Inicio de clases 2026-1 | clases | 2026-01-19 | 2026-01-19 | Primer día de actividades académicas. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 12 | 2 | Ceremonia de grados | ceremonia | 2026-06-20 | 2026-06-20 | Grados de pregrado y posgrado. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 13 | 2 | Primer corte evaluativo | examenes | 2026-03-09 | 2026-03-13 | Semana de evaluaciones del primer corte. | True | Google Sheets | 2026-11-18 17:44:38.424741+00:00 |
| 40 | 3 | Matrícula: inscripción de asignaturas del próximo periodo | matricula | 2026-12-20 | 2026-12-30 | Inscripción en línea de asignaturas por COSMOS. Revisa tus prerrequisitos antes de matricular. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 41 | 3 | Pago de matrícula del próximo periodo | pagos | 2026-12-20 | 2027-01-06 | Plazo para el pago de la matrícula ordinaria y reporte del recibo. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 42 | 3 | Publicación de notas del semestre | general | 2026-12-04 | 2026-12-04 | Consulta de calificaciones finales en COSMOS. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 43 | 3 | Exámenes finales | examenes | 2026-11-26 | 2026-12-03 | Semana de evaluaciones finales. Consulta el horario publicado por tu facultad. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 44 | 3 | Ceremonia de grados | ceremonia | 2026-12-12 | 2026-12-12 | Grados de pregrado y posgrado. Requiere paz y salvo y solicitud radicada. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 45 | 3 | Inicio de clases del próximo periodo | clases | 2027-01-13 | 2027-01-13 | Primer día de actividades académicas del nuevo semestre. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 46 | 3 | Fecha límite de adición y retiro de asignaturas | matricula | 2027-01-27 | 2027-01-27 | Último día para adicionar o retirar asignaturas sin afectar el historial. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 47 | 3 | Primer corte evaluativo | examenes | 2027-02-10 | 2027-02-14 | Semana de evaluaciones del primer corte. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 48 | 3 | Segundo corte evaluativo | examenes | 2027-03-10 | 2027-03-14 | Semana de evaluaciones del segundo corte. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 49 | 3 | Último día de clases | clases | 2027-04-07 | 2027-04-07 | Finalización de actividades docentes del semestre. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 50 | 3 | Exámenes finales del siguiente ciclo | examenes | 2027-04-11 | 2027-04-20 | Evaluaciones finales del semestre en curso. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 51 | 3 | Publicación de notas y habilitaciones | general | 2027-04-27 | 2027-04-27 | Publicación de notas finales y fechas de habilitación. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |
| 52 | 3 | Ceremonia de grados del siguiente ciclo | ceremonia | 2027-05-07 | 2027-05-07 | Grados de pregrado y posgrado del cierre de semestre. | True | demo-dinamico | 2026-11-22 18:13:05.479768+00:00 |

## `unab.noticias` (21 filas)

| id | titulo | resumen | contenido | url | fuente | categoria | fecha_publicacion | fecha_scrape | activo | notificada | embedding |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Convocatoria de monitorías académicas 2026-1 | La UNAB abre la convocatoria para monitorías en Ingeniería de Sistemas. | Los estudiantes con promedio superior a 4.0 pueden postularse como monitores académicos para el periodo 2026-1. | https://www.unab.edu.co/noticias/monitorias-2026-1 | UNAB | convocatoria | 2026-01-10 | 2026-11-18 17:44:38.424741+00:00 | True | False |  |
| 2 | Beca de excelencia académica | Postúlate a la beca de excelencia para el semestre 2026-1. | La beca cubre hasta el 75% del valor de la matrícula para estudiantes con promedio sobresaliente. | https://www.unab.edu.co/noticias/beca-excelencia-2026 | UNAB | beca | 2026-01-12 | 2026-11-18 17:44:38.424741+00:00 | True | False |  |
| 3 | Semana de la Ingeniería 2026 | Charlas, talleres y hackathon organizados por la Facultad de Ingeniería. | Del 21 al 25 de abril se realizará la Semana de la Ingeniería con actividades abiertas para todos los estudiantes. | https://www.unab.edu.co/noticias/semana-ingenieria-2026 | UNAB | evento | 2026-02-03 | 2026-11-18 17:44:38.424741+00:00 | True | False |  |
| 4 | Nuevos cursos de IA generativa | El CCD lanza cursos de IA generativa para estudiantes de pregrado. | Los cursos hacen parte de la Ruta de Competencias Digitales y no otorgan créditos académicos. | https://www.unab.edu.co/noticias/cursos-ia-2026 | UNAB | curso | 2026-02-10 | 2026-11-18 17:44:38.424741+00:00 | True | False |  |
| 5 | Calendario de exámenes finales disponible | Consulta las fechas de los exámenes finales del primer semestre 2026. | Las fechas fueron publicadas en COSMOS y en la página oficial de la universidad. | https://www.unab.edu.co/noticias/examenes-finales-2026-1 | UNAB | noticia | 2026-04-15 | 2026-11-18 17:44:38.424741+00:00 | True | False |  |
| 6 | Convocatoria de semilleros de investigación | Inscripciones abiertas para los semilleros del programa de Ingeniería de Sistemas. | Los semilleros de investigación reciben estudiantes desde segundo semestre. | https://www.unab.edu.co/noticias/semilleros-2026 | UNAB | convocatoria | 2026-02-20 | 2026-11-18 17:44:38.424741+00:00 | True | False |  |
| 20 | Universidad Autónoma de Bucaramanga subió 70 puestos en ranking QS y llegó al top 15 | Universidad Autónoma de Bucaramanga subió 70 puestos en ranking QS y llegó al top 15 LaRepublica.co | Universidad Autónoma de Bucaramanga subió 70 puestos en ranking QS y llegó al top 15 LaRepublica.co | https://news.google.com/rss/articles/CBMiogFBVV95cUxNbGs0RHJvVXR6N2drWTFHZDQzb015WlU2T195YlpCOXNJakhsa0VXdDdTVTdPTzluUjVhZzE3T1VBTldTa3FIVkRSX2o0b3NCalJqdlhhZlEydWgwRkNweDA2UDRvVEJZckh5QVc2Z2Z5QVVaUk5PcFFfVGdyVy0xdkJOWjZXazBaUHBBd3ZDaDFxaEpEQmgzbFBfSkRRNFI1elHSAaIBQVVfeXFMTS1iS1QxVDZpbHVNSUFsdk4wMk1LQlFkcS1yOXFzWTNSbWp1bm5RZ3VpYjNoWVA2UGotd01LUVNCNk9maXhsLWVlbWJFbVh3TTlkY2ZiWllncDhWbE1VODhib18tMmp6Q1hXckViUXpITUxRcXhubWRqWE1OQnJwU3dJYUJOUUltRk5YTnJldTVuTDlZbExsZ0FZbDdHTnA1Xzh3?oc=5 | LaRepublica.co | noticia | 2026-10-19 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 19 | Así se reinventa la UNAB para responder a los retos de la educación superior | Así se reinventa la UNAB para responder a los retos de la educación superior Revista Semana | Así se reinventa la UNAB para responder a los retos de la educación superior Revista Semana | https://news.google.com/rss/articles/CBMixAFBVV95cUxPM1NhY29kR1lBZEtFelNsM1BqRTJ2QUkyY20wcUJqRWJsYzVRaktLRTJhRElrT3pDellQQmlXLTFfN2dremJsVXp1MUVzeVF5clhZQmRzNndtZUVoVUI3MEtlcExyQUMwS0NDRG9BUUVRUEx1dDB5LWRzTi02Rm95MFBVWnNZVWZOaTZscE0yejJvRlBzUjR4d2ZCRWdyOUxrUUluSG9vazdHcE4zajJwTlBUX1g0Ykl1ckJob2RWc0g2Z0k00gHKAUFVX3lxTE10ckF3Slk2UEV1Q2liRTNRZkJRT0FkMHZTZktNbUNiV09UZnlicnNPMy13UU1nMWRacUdJQ2lWUVI0XzN1eTdOdGI5Mlo1eHEzUGpBb2JoZ21jU2NvaFVNYUtyT2dzUjJyMFZBVHNDUXFRRWlpN3hmR0taRUNpYUhrUl9fQ1JwQlV5SHI3SEJWYjB1QWcwUUlRSGdDcU1taGNQOTFYS3hRZUZMQ0RzWW9Xb3c2bjN1SUxscmlESlhfQVl1ZTdqSGFOaGc?oc=5 | Revista Semana | noticia | 2026-11-03 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 7 | Inscripciones abiertas para el semillero de inteligencia artificial | El semillero de IA del programa de Ingeniería de Sistemas recibe nuevos integrantes. | Los estudiantes interesados en machine learning, visión por computador o procesamiento de lenguaje natural pueden postularse al semillero. Se requieren ganas de aprender y disponibilidad de cuatro horas semanales. La inscripción se realiza con el profesor líder del semillero. | https://www.unab.edu.co/noticias/semillero-ia | UNAB | convocatoria | 2026-11-20 | 2026-11-18 17:44:42.701224+00:00 | True | False |  |
| 8 | Nuevo horario de atención de Registro Académico | La Oficina de Registro Académico amplía su atención presencial y virtual. | A partir de este mes la atención presencial es de lunes a viernes de 7:00 a 17:00 y la atención virtual de 8:00 a 18:00. Los trámites de certificados y solicitudes de grado se pueden radicar en COSMOS sin fila. | https://www.unab.edu.co/noticias/registro-academico-horario | UNAB | noticia | 2026-11-16 | 2026-11-18 17:44:42.701224+00:00 | True | False |  |
| 9 | Taller de preparación para exámenes finales | Bienestar Universitario y el CCD ofrecen un taller gratuito de técnicas de estudio. | El taller cubre organización del tiempo, métodos de repaso activo y manejo de ansiedad antes de los exámenes. Se realiza en modalidad híbrida y tiene cupos limitados. Inscríbete en el portal de Bienestar Universitario. | https://www.unab.edu.co/noticias/taller-examenes-finales | UNAB | evento | 2026-11-13 | 2026-11-18 17:44:42.701224+00:00 | True | False |  |
| 10 | Convocatoria de apoyo económico para transporte | La UNAB abre apoyos de transporte para estudiantes con dificultades económicas. | El apoyo cubre parte del costo de transporte durante el semestre. Pueden postularse estudiantes matriculados con carga académica igual o superior a 12 créditos que acrediten necesidad económica. La documentación se radica en Bienestar Universitario. | https://www.unab.edu.co/noticias/apoyo-transporte | UNAB | beca | 2026-11-08 | 2026-11-18 17:44:42.701224+00:00 | True | False |  |
| 23 | UNAB, primer lugar como universidad de Santander en medición internacional de sostenibilidad | UNAB, primer lugar como universidad de Santander en medición internacional de sostenibilidad Caracol Radio | UNAB, primer lugar como universidad de Santander en medición internacional de sostenibilidad Caracol Radio | https://news.google.com/rss/articles/CBMixAFBVV95cUxQZlNVazl1VGU1TUNGZEVCU2JXaVVXX2YwWF9wenBOa1dMbUhNSEphZi1ObjNERS04OFNaY29lOUhaeThIRkFWLXhMV3RmVFRKc0RUbDhvcUcxRVpKWjd4b0lfOElWZEFiUEkwUkdoeUhyc3N3Snk5Ti1palczQUVJZmludEhDdHlUMUhseGdYdW53YVltWEJOVG5GeGJqMzBHNU4xU2RBcy1Db2haeGZqZUFDR1ZzaTJ4Vnd4ZDMzZGk1WkdY0gHYAUFVX3lxTE5sUG5CRXJQYjFJeUstMUNTcS1JWHBtWkI3cWhjMDBxYWxMdXlfaHpOc2pYakdDNVg4UjcyVUhCZlZwMl9vejRmNzBxTG5Jel9hbzJnX29maktVeHNKQkZUaVNyaWE0ZE5YdGdLdnRwdEtibVJpUHRoT1NwWnpBWUhPT0RNUHVxR0MyWUpheUJ4UWM5cjU5SW9Fc0ZGLTdPczJ1ajh4THNFRUNsYUNZTmh2RFdDNUpHdEJkWk5SLUxoUFhtWkNLVEhkSjVfWTEzUXBsdTFCRHczRg?oc=5 | Caracol Radio | noticia | 2026-11-22 | 2026-11-23 17:01:01.393000+00:00 | True | False |  |
| 22 | UNAB se consolida entre las diez universidades más sostenibles de Colombia, según ranquin internacional | UNAB se consolida entre las diez universidades más sostenibles de Colombia, según ranquin internacional Metropolitano | UNAB se consolida entre las diez universidades más sostenibles de Colombia, según ranquin internacional Metropolitano | https://news.google.com/rss/articles/CBMilgFBVV95cUxNOWtpbmttU2VJM1h6QkhLeVdnUlMtd0w0QVlJbmpudjBXcXNid2hIUnZzREZaZDdCUFVVYllBd0JMTWNOSjB1Z1Rzb1lpcENZclZNLVZWamRJVHVXaEpjX3JuTWV3WkZsU2RWYjF6Z1VZNk1aOUd3Z3lRbEJyZWE2Nmx5eWVpajk3cTVQS2VISW1JT0JPblE?oc=5 | Metropolitano | noticia | 2026-11-20 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 26 | Las estrategias que ha implementado la UNAB para ahora hacer parte de las 200 mejores universidades de América Latina y ser referente en Santander | Las estrategias que ha implementado la UNAB para ahora hacer parte de las 200 mejores universidades de América Latina y ser referente en Santander El Tiempo | Las estrategias que ha implementado la UNAB para ahora hacer parte de las 200 mejores universidades de América Latina y ser referente en Santander El Tiempo | https://news.google.com/rss/articles/CBMipAJBVV95cUxPZWg4SEpiU2FPWUtVU2NkWEdJU3FhSW00WW9OdFlhczRYamM2R3ZGVWxTTlpjNHdrRkRwcnJMWEYzdGdNWUtJby0wMF9nYkxBYnAyYkxfWk1acWQ4RHVCZ3dhVE1fWHR1VlFkWkc4QnFBeGFwWmlHc3dJN2hXXzRTTGJsWHJwd2J3Q2ZoRWppamcxTHV3Yl95akFUZTZsRG05a1d1Zm1UelByMjhnWlBkdXc1VlcwZGd2WS0tNWE1NnBBNGE2OW1qb3NpODl3SnhTem40elB6bXB3NmJHUWRmaFkzNld0d0M1Z211dzZ3R2xTeGEyb29kTC15NDNxaGx0RXJvbnl2STZiOVREZng4dnM3QzJjenN5S2JxTWJtT1EzbmRm0gGqAkFVX3lxTE43UDFwZDRONFh5ZVlJRHltUVNFQkVGM0dKekR0QmgzR3BiNjhjZUR2eGRrQ29adjhTY0phZXdiN1RFcnJCWGlZeklaM3RXQ3ZwOXhKdFB6czFrQXBMU0hJa0dEYU5hZVhxeDZNNUNNY1hjZGZuNXRVTV9yRm1FM3ZFWllQVDR3U1lMT3UxUXY2bVo4enJpRUU4UFd1czc3VmRCeE1RdGNyNWRTSURvUkxCUjJzVDlPd19uMGJKM2MzeElrWDRVby1fMHFWS1dSYks2RXhPc1FjbU9IYUN2dG1RekVtblZkVWlSaGZQUmF4T3pWQnc1YjZHcXdJWWswcE52dXc1YlRsSTNqVEFFeGF0S0cweDhpWDZlQWpxcERfcWdoSTJoVzFqLVE?oc=5 | El Tiempo | noticia | 2026-10-09 | 2026-11-23 05:01:02.889000+00:00 | True | False |  |
| 24 | Tres universidades de Santander entre las 36 primeras del país en Saber Pro 2025. ¿Cuáles? | Tres universidades de Santander entre las 36 primeras del país en Saber Pro 2025. ¿Cuáles? Caracol Radio | Tres universidades de Santander entre las 36 primeras del país en Saber Pro 2025. ¿Cuáles? Caracol Radio | https://news.google.com/rss/articles/CBMivwFBVV95cUxOVy05MGNwcUM2a0VvR0ZCS0NMNjBXQ2RWSGR4OG9Hd0Z4R0VnRHVGLWNfWmVsTGVuajlBeDM2T2JyUi1jbHNuanhVbkNVN1R5bjhEYmwxZWJhWHNqaGVQcUFXb2RYTGh4Vjd1bklJZXdieHVWNl9WczNLQjIydkc1ZUYxYnJadzlFbnFzYmFMVGJfNTFuUnVNR09pU2lWUkltYllpdC1tUkFOYXVsR3RhS2hhTFhDRDlmd19RWEpEONIB0wFBVV95cUxOQkg5VmM1dFFYTUEyM2hPNHlITGhVTzlMTXJxZGtHRGVZNXZ2ZDRuSFV5TWlkaTd3S2cyalp2NE45RnlFdVlabVZ5RWdjSTZYM2M4SDhBVXRtSHRZMmtsdHIyTUhVZXV5M0NHZTZDbTh3QmNzcnEyX0xrMFFMb0RpUUh6MWk5SzVWYWx0V0FXbkV2d3EwY0psa3NMSWNQXzBuTkEwU0hYa0NQcFJQZ1VHMTVrYWh3cUwxcldDdGo5elNqMGlGSlFCbEZWaFk4MU1HM29r?oc=5 | Caracol Radio | noticia | 2026-10-10 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 21 | UNAB entra al grupo de las 200 mejores universidades de América Latina y el Caribe, según ranking QS | UNAB entra al grupo de las 200 mejores universidades de América Latina y el Caribe, según ranking QS Caracol Radio | UNAB entra al grupo de las 200 mejores universidades de América Latina y el Caribe, según ranking QS Caracol Radio | https://news.google.com/rss/articles/CBMizwFBVV95cUxOa21nQ1dPNTkzUUQ0V21hSTRXV0o4WVBjVFZSTVhveUhubVgwUnJIZVNpU2hvZHFXdXlIaURUdkl6S2Nxbk9KbVNJS082Tnl5bXpHRVJ4MGo2RDJrRS04azNNb1NZLW9UaEw1ZHRkNFoxOGhrT2oyTzJCckxKSmZkNGZ4aUVIaDJMalFkbkVTTWxmVUx3TkJpNjBEM2FRaDZGYTV2V3JmMnpNZzk0Z3M2bjFTUGpFLVcyX2lLUUN6ZlFJRHkyLUtFUjVsNk5YajjSAeMBQVVfeXFMTjFSMnRxMVBGVG5KcmhXQ1hwc0d6UDU0M25PWmNXelBVWEZkMjdzcmdkLW5RWUxJS1pwc09OdzZnek9qejY3QmJhRTRpakVkcC1qT3lFMzVYSUFmbnNDa3U2T2lPLXBNaUItOU1Qd19uNXRoM0lrRE14S0k5eEZGamNCZGFmOFpBejc2cjVtLU4xUlNKeTAxS0UyMnhpMUN0aHV0VVRwWmtjbFlITWdKZDBCY0FaMkxsLVA0cEliaU0xY3Y2MlplRFlaLTlZaVpLSW5aaTFYWC1oc2FfYmFhNmxtS2s?oc=5 | Caracol Radio | noticia | 2026-10-09 | 2026-11-23 05:01:02.889000+00:00 | True | False |  |
| 28 | UNAB, primer lugar como universidad de Santander en medición internacional de sostenibilidad | UNAB, primer lugar como universidad de Santander en medición internacional de sostenibilidad Caracol Radio | UNAB, primer lugar como universidad de Santander en medición internacional de sostenibilidad Caracol Radio | https://news.google.com/rss/articles/CBMi2AFBVV95cUxObFBuQkVyUGIxSXlLLTFDU3EtSVhwbVpCN3FoYzAwcWFsTHV5X2h6TnNqWGpHQzVYOFI3MlVIQmZWcDJfb3o0ZjcwcUxuSXpfYW8yZ19vZmpLVXhzSkJGVGlTcmlhNGROWHRnS3Z0cHRLYm1SaVB0aE9TcFp6QVlIT09ETVB1cUdDMllKYXlCeFFjOXI1OUlvRXNGRi03T3MydWo4eExzRUVDbGFDWU5odkRXQzVKR3RCZFpOUi1MaFBYbVpDS1RIZEo1X1kxM1FwbHUxQkR3M0bSAdgBQVVfeXFMTmxQbkJFclBiMUl5Sy0xQ1NxLUlYcG1aQjdxaGMwMHFhbEx1eV9oek5zalhqR0M1WDhSNzJVSEJmVnAyX296NGY3MHFMbkl6X2FvMmdfb2ZqS1V4c0pCRlRpU3JpYTRkTlh0Z0t2dHB0S2JtUmlQdGhPU3BaekFZSE9PRE1QdXFHQzJZSmF5QnhRYzlyNTlJb0VzRkYtN09zMnVqOHhMc0VFQ2xhQ1lOaHZEV0M1Skd0QmRaTlItTGhQWG1aQ0tUSGRKNV9ZMTNRcGx1MUJEdzNG?oc=5 | Caracol Radio | noticia | 2026-11-22 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 30 | La UIS fortalece el intercambio de experiencias para una educación superior más inclusiva | La UIS fortalece el intercambio de experiencias para una educación superior más inclusiva Universidad Industrial de Santander | La UIS fortalece el intercambio de experiencias para una educación superior más inclusiva Universidad Industrial de Santander | https://news.google.com/rss/articles/CBMikwFBVV95cUxOdXAyN2trY1AtU01CcVY1VHFVeXpfTndfSEkwRjFnWnFERTdkaHZuM2JfLVF3MFloZUFqTFNhc0lUUVQ2TzY5SGNLNlZfUHo4amhQbmltWkF5YUVlZnRpd2ZKZzAxTGxkNVgwVWttYUlCM3h0U1dPOVZXM2JlUlYteHJOZFk4Z0xsR2haaVprdy1fLUU?oc=5 | Universidad Industrial de Santander | noticia | 2026-10-20 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 80 | Murió Alberto Montoya Puyana, el arquitecto que marcó la política y educación en Santander | Murió Alberto Montoya Puyana, el arquitecto que marcó la política y educación en Santander Blu Radio | Murió Alberto Montoya Puyana, el arquitecto que marcó la política y educación en Santander Blu Radio | https://news.google.com/rss/articles/CBMi1wFBVV95cUxPT2JFM05BVnZucnB2Y1FtNGpkS2ppMzc0R0EwNk9kSUJ0c3RaYm5QUVlieHhEVkprLUhRckI3dkc2YWd1eEZTb1FDVlRJTWl1N3p6R0luaDgwNl9EeGFvRGFlYXJTTWhlZkJ4N0xWUXZ0c0VPbVF6X3M3SnR6STh0dUxBWXhfTHhlWGtXLXV1MkNwQjBsQkloZmVlck15NTN0YVhLRmNhSjJMajFmUXc2RUQ2Rk9lQ1ZKN2FGMkNXaGZPdjQ2NWJQSUZKTF9mQlZIVTVNdHVGY9IB5AFBVV95cUxPZmF2U2dqZWVjcF8wMDNOZHRaRjdJZEF2UDJCRUpYSmtFTEs4SEZBTWpNeE90TDlESnZzWmc4YUNOMzBFZ0ZlM0xINHFEVDlBajhRU2F5Y2Vha2FrNmlaSmFrR2QyVk03TE1fbDZQNFNhREVUZGxWSjhGalVOenZ5TndadGVINmpKcjZYWGxyN3VDOXp4Mk56WDBsdDNFaDQ4OGxRU0JJa1U5Y0hNWGlKWnBnejRpdFJNQzdPY2dzeVVYbDZVQTg2V2V5dHZuRUZhb1RETjg5eG5DZ1dwX2xESTE0am4?oc=5 | Blu Radio | noticia | 2026-11-23 | 2026-11-23 17:01:03.343000+00:00 | True | False |  |
| 33 | Politécnico de Bucaramanga ganó primer puesto de investigación con un proyecto de inteligencia artificial | Politécnico de Bucaramanga ganó primer puesto de investigación con un proyecto de inteligencia artificial Vanguardia | Politécnico de Bucaramanga ganó primer puesto de investigación con un proyecto de inteligencia artificial Vanguardia | https://news.google.com/rss/articles/CBMijAJBVV95cUxPTVBoYzVMQ1BTejdNcFNGQWttQXJaT044SmpWeDhNMGlqa1ZvNHFmb0NYOHctWU9nLTZ0czQtOXcxYkhwYndrdnNoNUVYWi1xYjUybjNpb04ya1RXTXUtWHdyUGxVZmhtOWF4OXZHVmd5dkVjQnlORS1iNzZsc21HWVFUMmFUaFZKZ0l0LWFnSDgzRVdmNUpnaVRoYTQ5NExOMWtRU0J5c3h3dHFfYm1JVFJDanhRVks4SDUzeXZQVjYtelVyR091ckVXQU5lVHg4X2dGQ0NPVU9BNEFjSHpkbktfMjBRUUk3aGV3RU5tRmx5cUxGbjVnR1VsVHBOakxtYU1NZUo2RUU3NUky?oc=5 | Vanguardia | noticia | 2026-10-22 | 2026-11-23 17:01:03.344000+00:00 | True | False |  |

## `unab.documentos` (7 filas)

| id | titulo | fuente | tipo | categoria | version | hash_contenido | num_chunks | procesado | created_at | updated_at |
|---|---|---|---|---|---|---|---|---|---|---|
| 3 | Becas, descuentos y monitorías | becas_monitorias.md | markdown | becas | 1.0 | 6106feb72ac6f29bad14284bf376c0f9bcfb14c8a5fb2883888e4ab00922960d | 3 | True | 2026-11-18 17:44:42.074335+00:00 | 2026-11-22 21:17:26.382183+00:00 |
| 1 | Bienestar Universitario | bienestar_universitario.md | markdown | bienestar | 1.0 | 65454c7d651445fc3fe875e448ec9a56c90121ceb0a774076e2e7bd454f980c7 | 2 | True | 2026-11-18 17:44:42.074335+00:00 | 2026-11-22 21:17:28.371955+00:00 |
| 4 | Centro de Competencias Digitales (CCD) | ccd_competencias_digitales.md | markdown | ccd | 1.0 | 1bd3dfa39bb7e50468dec7c3eae68744b3df2c72889674f3aae06c0ae3e96e88 | 4 | True | 2026-11-18 17:44:42.074335+00:00 | 2026-11-22 21:17:30.592091+00:00 |
| 2 | Preguntas frecuentes académicas | faq_academica.md | markdown | faq | 1.0 | 48e28c7a331141694ef0e0c2e36f1e0415463d3cc0f1c66d7cc54a1fb55c8ec9 | 5 | True | 2026-11-18 17:44:42.074335+00:00 | 2026-11-22 21:17:32.454233+00:00 |
| 17 | Plan de Estudios Ingeniería de Sistemas UNAB | plan_estudios_ingenieria_sistemas.md | markdown | plan_estudios | 1.0 | 8e17d820ca4675f5862509adecd48e5f194722b1684d99437bdccde719a1f737 | 4 | True | 2026-11-22 21:17:34.885777+00:00 | 2026-11-22 21:17:34.885777+00:00 |
| 5 | Requisitos y opciones de grado | proceso_grado.md | markdown | grado | 1.0 | 18d42e7e5d5b18e68bb7598c8a6f95baab66c88eab2fed54b67c05a99b32a788 | 3 | True | 2026-11-18 17:44:42.074335+00:00 | 2026-11-22 21:17:46.094153+00:00 |
| 6 | Reglamento Estudiantil UNAB | reglamento_estudiantil.md | markdown | reglamento | 1.0 | 2bb2f9c552b7a7015a1376ae264b217b985556ad71f7bc7ad106b16a70bc2990 | 6 | True | 2026-11-18 17:44:42.074335+00:00 | 2026-11-22 21:17:48.388138+00:00 |

## `unab.historial_academico` (908 filas — se muestran 20)

| id | id_estudiante | id_curso | periodo | nota | estado | creditos | intento | docente | fecha_matricula | fecha_cierre | created_at |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | 10045260 | 1 | 2025-2 | 3.2 | aprobado | 4 | 1 |  | 2025-07-21 | 2025-11-21 | 2026-11-18 17:44:38.424741+00:00 |
| 2 | 10045259 | 1 | 2024-2 | 4.1 | aprobado | 4 | 1 |  | 2024-07-15 | 2024-11-15 | 2026-11-18 17:44:38.424741+00:00 |
| 3 | 10045258 | 1 | 2023-2 | 3.0 | aprobado | 4 | 1 |  | 2023-07-17 | 2023-11-17 | 2026-11-18 17:44:38.424741+00:00 |
| 4 | 10045257 | 1 | 2022-2 | 4.1 | aprobado | 4 | 1 |  | 2022-07-18 | 2022-11-18 | 2026-11-18 17:44:38.424741+00:00 |
| 5 | 10045256 | 1 | 2021-2 | 4.0 | aprobado | 4 | 1 |  | 2021-07-19 | 2021-11-19 | 2026-11-18 17:44:38.424741+00:00 |
| 6 | 10045254 | 1 | 2025-1 | 4.8 | aprobado | 4 | 1 |  | 2025-01-20 | 2025-05-20 | 2026-11-18 17:44:38.424741+00:00 |
| 7 | 10045253 | 1 | 2024-1 | 4.7 | aprobado | 4 | 1 |  | 2024-01-15 | 2024-05-15 | 2026-11-18 17:44:38.424741+00:00 |
| 8 | 10045252 | 1 | 2023-1 | 3.5 | aprobado | 4 | 1 |  | 2023-01-16 | 2023-05-16 | 2026-11-18 17:44:38.424741+00:00 |
| 9 | 10045251 | 1 | 2022-1 | 4.6 | aprobado | 4 | 1 |  | 2022-01-17 | 2022-05-17 | 2026-11-18 17:44:38.424741+00:00 |
| 10 | 10045250 | 1 | 2025-2 | 4.5 | aprobado | 4 | 1 |  | 2025-07-21 | 2025-11-21 | 2026-11-18 17:44:38.424741+00:00 |
| 11 | 10045249 | 1 | 2024-2 | 4.3 | aprobado | 4 | 1 |  | 2024-07-15 | 2024-11-15 | 2026-11-18 17:44:38.424741+00:00 |
| 12 | 10045248 | 1 | 2023-2 | 4.7 | aprobado | 4 | 1 |  | 2023-07-17 | 2023-11-17 | 2026-11-18 17:44:38.424741+00:00 |
| 13 | 10045247 | 1 | 2022-2 | 3.8 | aprobado | 4 | 1 |  | 2022-07-18 | 2022-11-18 | 2026-11-18 17:44:38.424741+00:00 |
| 14 | 10045246 | 1 | 2021-2 | 4.7 | aprobado | 4 | 1 |  | 2021-07-19 | 2021-11-19 | 2026-11-18 17:44:38.424741+00:00 |
| 15 | 10045244 | 1 | 2025-1 | 4.5 | aprobado | 4 | 1 |  | 2025-01-20 | 2025-05-20 | 2026-11-18 17:44:38.424741+00:00 |
| 16 | 10045243 | 1 | 2024-1 | 4.8 | aprobado | 4 | 1 |  | 2024-01-15 | 2024-05-15 | 2026-11-18 17:44:38.424741+00:00 |
| 17 | 10045242 | 1 | 2023-1 | 4.6 | aprobado | 4 | 1 |  | 2023-01-16 | 2023-05-16 | 2026-11-18 17:44:38.424741+00:00 |
| 18 | 10045241 | 1 | 2022-1 | 3.9 | aprobado | 4 | 1 |  | 2022-01-17 | 2022-05-17 | 2026-11-18 17:44:38.424741+00:00 |
| 20 | 10045239 | 1 | 2024-2 | 4.6 | aprobado | 4 | 1 |  | 2024-07-15 | 2024-11-15 | 2026-11-18 17:44:38.424741+00:00 |
| 21 | 10045238 | 1 | 2023-2 | 4.4 | aprobado | 4 | 1 |  | 2023-07-17 | 2023-11-17 | 2026-11-18 17:44:38.424741+00:00 |

## `unab.conversaciones` (61 filas — se muestran 10)

| id | session_id | canal | id_estudiante | pregunta | respuesta | tipo | fuentes | tokens_usados | latencia_ms | feedback | created_at |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | anon-1795375713487 | android |  | Noticias y convocatorias UNAB | Se encontraron 10 noticias o convocatorias. | noticias | {} | 0 | 1228 |  | 2026-11-22 19:28:35.130599+00:00 |
| 2 | anon-1795375927342 | android |  | Noticias y convocatorias UNAB | Se encontraron 10 noticias o convocatorias. | noticias | {} | 0 | 1199 |  | 2026-11-22 19:32:08.817948+00:00 |
| 3 | anon-1795376338473 | android |  | Noticias y convocatorias UNAB | Se encontraron 10 noticias o convocatorias. | noticias | {} | 0 | 1179 |  | 2026-11-22 19:38:59.920809+00:00 |
| 4 | demo-cal | android |  | ¿Cuándo son los exámenes finales? | Para el periodo académico activo (Segundo semestre 2026), los **Exámenes finales** están programados del **26/11/2026** al **03/12/2026**. ¡Faltan **4 días** para que comiencen!   Recuerda que las fechas oficiales pueden cambiar y deben confirmarse en la Secretaría General. | calendario | {} | 0 | 5629 |  | 2026-11-22 19:41:53.145465+00:00 |
| 5 | demo-acad | android | 10045234 | ¿Cómo va mi promedio? | ¡Hola, Jhon! Aquí tienes el resumen de tu estado académico actual en Ingeniería de Sistemas:  * **(a) Resumen del estado:** Tu promedio acumulado es de **3.69**. Te encuentras en 3.er semestre y llevas un avance del **18.8%** de tu carrera (30 créditos aprobados de 160 totales). * **(b) Cursos:** Tienes 10 cursos aprobados, 4 en curso y **1 curso reprobado**. * **(c) Riesgos y bloqueos:** Presentas alertas importantes debido al curso reprobado, lo que genera **6 cursos bloqueados** por prerrequisito pendiente. * **(d) Recomendación:** Te sugiero revisar el detalle de tus asignaturas con tu director de programa para planear la recuperación de los prerrequisitos bloqueados y asegurar una adecuada inscripción en el próximo periodo.   ¿Te gustaría que consultemos tus cursos bloqueados o agendemos una solicitud de consejería? | academico | {} | 0 | 9116 |  | 2026-11-22 19:42:02.464200+00:00 |
| 6 | anon-1795376522807 | android |  | Noticias y convocatorias UNAB | Se encontraron 10 noticias o convocatorias. | noticias | {} | 0 | 182 |  | 2026-11-22 19:42:03.257131+00:00 |
| 7 | demo-rag-retry-0 | android |  | ¿Cuáles son los requisitos de grado? | ¡Hola! Para obtener el título de pregrado en la UNAB, debes cumplir con los siguientes requisitos principales:  1. **Aprobar el 100% de los créditos** de tu plan de estudios. 2. Mantener un **promedio acumulado igual o superior a 3.0**. 3. Cumplir con las **horas de práctica o trabajo de grado** según las opciones de tu programa. 4. Estar a **paz y salvo** con la universidad. 5. Acreditar el **requisito de segunda lengua** y las **competencias digitales** definidas por el CCD. 6. Radicar la solicitud de grado en Registro Académico en las fechas establecidas en el calendario académico.  Fuente: proceso_grado.md | rag | {} | 0 | 7475 |  | 2026-11-22 19:43:47.854857+00:00 |
| 8 | demo-rag | android |  | ¿Cuáles son los requisitos de grado? | ¡Hola! Para obtener el título de pregrado en la UNAB, debes cumplir con los siguientes requisitos principales:  1. **Aprobar el 100% de los créditos** de tu plan de estudios. 2. Mantener un **promedio acumulado de 3.0 o superior**. 3. Cumplir con las **horas de práctica o trabajo de grado** correspondientes. 4. Estar a **paz y salvo** con la universidad. 5. Acreditar el **requisito de segunda lengua** y las competencias digitales definidas por el CCD. 6. Radicar la solicitud de grado en Registro Académico en las fechas establecidas en el calendario académico.  Fuente: proceso_grado.md | rag | {} | 0 | 3736 |  | 2026-11-22 19:43:57.421230+00:00 |
| 9 | demo-cal | android |  | ¿Cuándo son los exámenes finales? | Para el periodo académico activo (Segundo semestre 2026), los **Exámenes finales** se realizarán del **26/11/2026** al **03/12/2026**. ¡Faltan **4 días** para que inicien!   Recuerda que las fechas oficiales pueden cambiar y deben confirmarse en la Secretaría General. | calendario | {} | 0 | 3978 |  | 2026-11-22 19:44:01.904647+00:00 |
| 10 | demo-acad | android | 10045234 | ¿Cómo va mi promedio? | Hola, Jhon. Aquí tienes el detalle de tu situación académica:  * **(a) Resumen del estado:** Tu promedio acumulado es de **3.69**. Estás cursando 3.er semestre en el programa de **Ingeniería de Sistemas**, con un avance del **18.8%** (30 créditos aprobados de 160). * **(b) Cursos relevantes:** Tienes 10 asignaturas aprobadas, 4 en curso y 1 reprobada (**Cálculo Integral**, con nota de 2.4). * **(c) Riesgos y bloqueos:** Tienes **6 cursos bloqueados** debido a prerrequisitos pendientes, principalmente derivados de la asignatura de Cálculo Integral que debes recuperar. * **(d) Recomendación de matrícula:** Para tu próximo periodo se recomienda priorizar la inscripción de **Cálculo Integral** junto con otras materias que no tengan prerrequisitos pendientes (como Probabilidad y Estadística, Teoría de Lenguajes y Autómatas, o electivas), completando hasta 18 créditos.  Te sugiero programar una cita con tu director de programa para planear adecuadamente la recuperación de las materias bloqueadas y asegurar tu avance óptimo en la carrera. | academico | {} | 0 | 8786 |  | 2026-11-22 19:44:11.199377+00:00 |

## `unab.notificaciones` (0 filas — se muestran 0)

| id | id_estudiante | titulo | mensaje | tipo | referencia_id | leida | enviada_push | created_at |
|---|---|---|---|---|---|---|---|---|

## `unab.solicitudes` (0 filas — se muestran 0)

| id | id_estudiante | nombre_estudiante | tipo_solicitud | descripcion | estado | prioridad | asignado_a | enviado_sheets | created_at | updated_at |
|---|---|---|---|---|---|---|---|---|---|---|

## `unab.dispositivos` (0 filas — se muestran 0)

| id | id_estudiante | fcm_token | plataforma | activo | updated_at |
|---|---|---|---|---|---|

## `unab.documentos_vectoriales` (27 filas — se muestran todas, sin imprimir el vector)

| id | contenido | fuente | titulo | chunk | modelo | dimensiones | overlap |
|---|---|---|---|---|---|---|---|
| b3b2cf26-8947-46d1-a8af-3f236f13b63d | La Beca de Excelencia Académica reconoce a los estudiantes con promedio acumulado sobresal | becas_monitorias.md | Becas, descuentos y monitorías | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| 6922049e-ea9c-44f0-858c-f38389c7d918 | mantiene el promedio y no tiene sanciones disciplinarias. La convocatoria se publica al fi | becas_monitorias.md | Becas, descuentos y monitorías | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| fac1db4c-3996-4595-ac86-2a738d303e45 | haber aprobado la asignatura y disponer de al menos 12 horas semanales. La postulación se  | becas_monitorias.md | Becas, descuentos y monitorías | 3 | gemini:gemini-embedding-001 | 1536 | 160 |
| 64bb1fea-0e56-4a3b-84a7-e52e892d7123 | Bienestar Universitario ofrece acompañamiento psicológico, orientación vocacional, trabajo | bienestar_universitario.md | Bienestar Universitario | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| d0fd5f2e-d401-48e0-9f50-5cf0cd8ee996 | solicitan de forma presencial o por el correo de bienestar. Las citas de consejería son co | bienestar_universitario.md | Bienestar Universitario | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| bf9715ba-e7e1-44ff-aa84-ca1a9dad7ff4 | El Centro de Competencias Digitales (CCD) de la UNAB acompaña la formación en habilidades  | ccd_competencias_digitales.md | Centro de Competencias Digitales (CCD) | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| 1fa6a031-c551-46cd-90a6-b0e06c4a9c94 | en cinco áreas: alfabetización digital, comunicación y colaboración, creación de contenido | ccd_competencias_digitales.md | Centro de Competencias Digitales (CCD) | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| e82db0ec-f96a-4152-a35b-137336f9981b | nivel completado. Completar la ruta es un requisito de competencias digitales para el grad | ccd_competencias_digitales.md | Centro de Competencias Digitales (CCD) | 3 | gemini:gemini-embedding-001 | 1536 | 160 |
| 7853f932-af4f-412f-863b-32c3b46a30a4 | la autoría del trabajo. No está permitido presentar texto generado por IA como propio ni u | ccd_competencias_digitales.md | Centro de Competencias Digitales (CCD) | 4 | gemini:gemini-embedding-001 | 1536 | 160 |
| 462bf728-f564-4c9d-9eb7-dbc539bfb7b9 | ¿Cuántos créditos puedo matricular? El límite normal es de 18 a 20 créditos por semestre.  | faq_academica.md | Preguntas frecuentes académicas | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| 933f2047-0b28-4121-8f00-074edcb96426 | hasta 22 créditos. Los estudiantes en periodo de prueba académica deben matricular entre 9 | faq_academica.md | Preguntas frecuentes académicas | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| cf89b866-8671-492b-b146-30512646a168 | aprobados por semestre. Puedes consultar ambos indicadores en COSMOS, en la opción "Avance | faq_academica.md | Preguntas frecuentes académicas | 3 | gemini:gemini-embedding-001 | 1536 | 160 |
| 7f2c8add-661b-433b-a468-fba563e627a5 | respete los prerrequisitos y tu límite de créditos. Si la pérdida afecta tu promedio, soli | faq_academica.md | Preguntas frecuentes académicas | 4 | gemini:gemini-embedding-001 | 1536 | 160 |
| 3e75436b-6a49-4fe1-803c-4c4a0b7efe3d | de apoyo académico complementa a COSMOS: responde preguntas, explica el reglamento y ayuda | faq_academica.md | Preguntas frecuentes académicas | 5 | gemini:gemini-embedding-001 | 1536 | 160 |
| 0cccabe3-635c-4e06-8925-2fe1c1c6f051 | El plan de estudios de Ingeniería de Sistemas de la UNAB está organizado en ocho semestres | plan_estudios_ingenieria_sistemas.md | Plan de Estudios Ingeniería de Sistemas UNAB | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| 8d47140c-86e1-4467-965c-d7b197a259ec | objetivo es que el estudiante pase de la resolución de problemas al diseño de sistemas int | plan_estudios_ingenieria_sistemas.md | Plan de Estudios Ingeniería de Sistemas UNAB | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| f38a5a7f-a608-4d2d-921b-25e5808fc34f | bloquea Cálculo Multivariado, y la de Programación II bloquea Estructuras de Datos; el rob | plan_estudios_ingenieria_sistemas.md | Plan de Estudios Ingeniería de Sistemas UNAB | 3 | gemini:gemini-embedding-001 | 1536 | 160 |
| 5db6a235-3d83-4e47-ba5a-d7f5f32ad68d | ciberseguridad o desarrollo móvil. El proyecto de grado se inscribe en el séptimo semestre | plan_estudios_ingenieria_sistemas.md | Plan de Estudios Ingeniería de Sistemas UNAB | 4 | gemini:gemini-embedding-001 | 1536 | 160 |
| c9264ed5-6303-4c7f-88ce-e428db43fc1b | Para obtener el título de pregrado el estudiante debe aprobar el 100% de los créditos del  | proceso_grado.md | Requisitos y opciones de grado | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| c24cee65-7d6a-480c-b1ef-2075ca48c335 | lengua y las competencias digitales definidas por el CCD. La solicitud de grado se radica  | proceso_grado.md | Requisitos y opciones de grado | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| 9a7b31ae-199e-44eb-b6c9-bd75d689965a | El estudiante debe inscribir la opción en el semestre en que la va a desarrollar y present | proceso_grado.md | Requisitos y opciones de grado | 3 | gemini:gemini-embedding-001 | 1536 | 160 |
| a47a6a88-c7ea-4764-b72f-30300df32745 | El Reglamento Estudiantil de la UNAB regula los derechos y deberes de los estudiantes de p | reglamento_estudiantil.md | Reglamento Estudiantil UNAB | 1 | gemini:gemini-embedding-001 | 1536 | 160 |
| 478382ad-d528-4b38-a678-ed686d001756 | los servicios de bienestar universitario. Los deberes incluyen asistir a clase, respetar a | reglamento_estudiantil.md | Reglamento Estudiantil UNAB | 2 | gemini:gemini-embedding-001 | 1536 | 160 |
| c9301a5e-b597-4246-9c8f-c791b08dfaf8 | estudiante considera que una nota es incorrecta, puede solicitar revisión por escrito al p | reglamento_estudiantil.md | Reglamento Estudiantil UNAB | 3 | gemini:gemini-embedding-001 | 1536 | 160 |
| 5d4dea1a-e956-4788-a936-2f99b513b3c9 | que define un plan de acompañamiento. La reprobación afecta el promedio acumulado y puede  | reglamento_estudiantil.md | Reglamento Estudiantil UNAB | 4 | gemini:gemini-embedding-001 | 1536 | 160 |
| e39ff8a8-aa5d-491a-8888-41ac08470826 | correquisitos, en cambio, deben matricularse en el mismo periodo. La malla curricular de c | reglamento_estudiantil.md | Reglamento Estudiantil UNAB | 5 | gemini:gemini-embedding-001 | 1536 | 160 |
| c3a54a0b-ae9d-41bb-9070-1ba9b09e24a5 | al estudiante con menos del 60% de los créditos matriculados, se considera retiro voluntar | reglamento_estudiantil.md | Reglamento Estudiantil UNAB | 6 | gemini:gemini-embedding-001 | 1536 | 160 |
