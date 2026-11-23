import '../utils/json_utils.dart';

/// Resumen académico completo que devuelve `POST /webhook/unab/academico/resumen`.
class AcademicSummary {
  const AcademicSummary({
    required this.ok,
    this.error,
    this.estado,
    this.avance,
    this.proyeccion,
    this.alertas,
    this.bloqueados = const <BlockedCourse>[],
    this.historial = const <HistoryEntry>[],
  });

  final bool ok;
  final String? error;
  final AcademicState? estado;
  final AcademicProgress? avance;
  final AcademicProjection? proyeccion;
  final AcademicAlert? alertas;
  final List<BlockedCourse> bloqueados;
  final List<HistoryEntry> historial;

  bool get isEmpty => estado == null && avance == null;

  factory AcademicSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> estadoJson = asMap(json['estado']);
    final Map<String, dynamic> avanceJson = asMap(json['avance']);
    final Map<String, dynamic> proyeccionJson = asMap(json['proyeccion']);

    // `alertas` llega como arreglo con la fila de `v_alertas_academicas`
    // (json_agg), pero también aceptamos un objeto plano.
    final List<dynamic> alertasList = asList(json['alertas']);
    final Map<String, dynamic> alertasJson = alertasList.isNotEmpty
        ? asMap(alertasList.first)
        : asMap(json['alertas']);

    return AcademicSummary(
      ok: asBool(json['ok']) && estadoJson.isNotEmpty,
      error: asString(json['error']),
      estado: estadoJson.isEmpty ? null : AcademicState.fromJson(estadoJson),
      avance: avanceJson.isEmpty ? null : AcademicProgress.fromJson(avanceJson),
      proyeccion: proyeccionJson.isEmpty
          ? null
          : AcademicProjection.fromJson(proyeccionJson),
      alertas: alertasJson.isEmpty ? null : AcademicAlert.fromJson(alertasJson),
      bloqueados: asList(json['bloqueados'])
          .map((dynamic item) => BlockedCourse.fromJson(asMap(item)))
          .where((BlockedCourse item) => item.cursoBloqueado.isNotEmpty)
          .toList(growable: false),
      historial: asList(json['historial'])
          .map((dynamic item) => HistoryEntry.fromJson(asMap(item)))
          .where((HistoryEntry item) => item.codigoCurso.isNotEmpty)
          .toList(growable: false),
    );
  }
}

/// Fila de `unab.v_estado_estudiante`.
class AcademicState {
  const AcademicState({
    required this.idEstudiante,
    required this.nombreCompleto,
    this.email,
    this.telefono,
    this.codigoPrograma,
    required this.programa,
    this.semestreActual,
    this.fechaIngreso,
    required this.estadoEstudiante,
    required this.promedioAcumulado,
    required this.cursosRegistrados,
    required this.cursosAprobados,
    required this.cursosEnCurso,
    required this.cursosReprobados,
    required this.creditosAprobados,
    required this.creditosEnCurso,
  });

  final String idEstudiante;
  final String nombreCompleto;
  final String? email;
  final String? telefono;
  final String? codigoPrograma;
  final String programa;
  final int? semestreActual;
  final DateTime? fechaIngreso;
  final String estadoEstudiante;
  final double promedioAcumulado;
  final int cursosRegistrados;
  final int cursosAprobados;
  final int cursosEnCurso;
  final int cursosReprobados;
  final int creditosAprobados;
  final int creditosEnCurso;

  factory AcademicState.fromJson(Map<String, dynamic> json) {
    return AcademicState(
      idEstudiante: asString(json['id_estudiante']) ?? '',
      nombreCompleto: asString(json['nombre_completo']) ?? 'Estudiante',
      email: asString(json['email']),
      telefono: asString(json['telefono']),
      codigoPrograma: asString(json['codigo_programa']),
      programa: asString(json['programa']) ?? 'Programa no asignado',
      semestreActual: asInt(json['semestre_actual']),
      fechaIngreso: asDate(json['fecha_ingreso']),
      estadoEstudiante: asString(json['estado_estudiante']) ?? 'activo',
      promedioAcumulado: asDouble(json['promedio_acumulado']) ?? 0,
      cursosRegistrados: asInt(json['cursos_registrados']) ?? 0,
      cursosAprobados: asInt(json['cursos_aprobados']) ?? 0,
      cursosEnCurso: asInt(json['cursos_en_curso']) ?? 0,
      cursosReprobados: asInt(json['cursos_reprobados']) ?? 0,
      creditosAprobados: asInt(json['creditos_aprobados']) ?? 0,
      creditosEnCurso: asInt(json['creditos_en_curso']) ?? 0,
    );
  }
}

/// Fila de `unab.v_avance_plan`.
class AcademicProgress {
  const AcademicProgress({
    required this.programa,
    required this.creditosTotales,
    required this.semestresTotales,
    this.semestreActual,
    required this.creditosAprobados,
    required this.creditosPendientes,
    required this.porcentajeAvance,
    required this.promedioAcumulado,
  });

  final String programa;
  final int creditosTotales;
  final int semestresTotales;
  final int? semestreActual;
  final int creditosAprobados;
  final int creditosPendientes;
  final double porcentajeAvance;
  final double promedioAcumulado;

  factory AcademicProgress.fromJson(Map<String, dynamic> json) {
    return AcademicProgress(
      programa: asString(json['programa']) ?? 'Programa no asignado',
      creditosTotales: asInt(json['creditos_totales']) ?? 0,
      semestresTotales: asInt(json['semestres_totales']) ?? 0,
      semestreActual: asInt(json['semestre_actual']),
      creditosAprobados: asInt(json['creditos_aprobados']) ?? 0,
      creditosPendientes: asInt(json['creditos_pendientes']) ?? 0,
      porcentajeAvance: asDouble(json['porcentaje_avance']) ?? 0,
      promedioAcumulado: asDouble(json['promedio_acumulado']) ?? 0,
    );
  }
}

/// Fila de `unab.v_proyeccion_semestres`.
class AcademicProjection {
  const AcademicProjection({
    required this.creditosTotales,
    required this.creditosAprobados,
    required this.creditosEnCurso,
    required this.creditosRestantes,
    required this.ritmoCreditosSemestre,
    this.semestresRestantesEstimados,
    this.semestreProyectadoGrado,
    required this.porcentajeAvance,
  });

  final int creditosTotales;
  final int creditosAprobados;
  final int creditosEnCurso;
  final int creditosRestantes;
  final double ritmoCreditosSemestre;
  final int? semestresRestantesEstimados;
  final int? semestreProyectadoGrado;
  final double porcentajeAvance;

  factory AcademicProjection.fromJson(Map<String, dynamic> json) {
    return AcademicProjection(
      creditosTotales: asInt(json['creditos_totales']) ?? 0,
      creditosAprobados: asInt(json['creditos_aprobados']) ?? 0,
      creditosEnCurso: asInt(json['creditos_en_curso']) ?? 0,
      creditosRestantes: asInt(json['creditos_restantes']) ?? 0,
      ritmoCreditosSemestre: asDouble(json['ritmo_creditos_semestre']) ?? 0,
      semestresRestantesEstimados: asInt(json['semestres_restantes_estimados']),
      semestreProyectadoGrado: asInt(json['semestre_proyectado_grado']),
      porcentajeAvance: asDouble(json['porcentaje_avance']) ?? 0,
    );
  }
}

/// Fila de `unab.v_alertas_academicas`.
class AcademicAlert {
  const AcademicAlert({
    required this.cursosReprobados,
    required this.cursosBloqueados,
    required this.cursosEnCurso,
    required this.mensajes,
  });

  final int cursosReprobados;
  final int cursosBloqueados;
  final int cursosEnCurso;
  final List<String> mensajes;

  bool get hasAlerts => mensajes.isNotEmpty;

  factory AcademicAlert.fromJson(Map<String, dynamic> json) {
    return AcademicAlert(
      cursosReprobados: asInt(json['cursos_reprobados']) ?? 0,
      cursosBloqueados: asInt(json['cursos_bloqueados']) ?? 0,
      cursosEnCurso: asInt(json['cursos_en_curso']) ?? 0,
      mensajes: asList(json['alertas'])
          .map((dynamic item) => item.toString())
          .where((String item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }
}

/// Curso bloqueado por prerrequisito (`unab.v_prerrequisitos_pendientes`).
class BlockedCourse {
  const BlockedCourse({
    required this.cursoBloqueado,
    required this.nombreCurso,
    this.semestreSugerido,
    required this.codigoPrerequisito,
    required this.nombrePrerequisito,
    required this.estadoPrerequisito,
    required this.tipoBloqueo,
    this.notaPrerequisito,
  });

  final String cursoBloqueado;
  final String nombreCurso;
  final int? semestreSugerido;
  final String codigoPrerequisito;
  final String nombrePrerequisito;
  final String estadoPrerequisito;
  final String tipoBloqueo;
  final double? notaPrerequisito;

  String get tipoBloqueoLabel {
    switch (tipoBloqueo) {
      case 'prerrequisito_reprobado':
        return 'Prerrequisito reprobado';
      case 'prerrequisito_en_curso':
        return 'Prerrequisito en curso';
      default:
        return 'Prerrequisito pendiente';
    }
  }

  factory BlockedCourse.fromJson(Map<String, dynamic> json) {
    return BlockedCourse(
      cursoBloqueado: asString(json['curso_bloqueado']) ?? '',
      nombreCurso: asString(json['nombre_curso']) ?? 'Curso',
      semestreSugerido: asInt(json['semestre_sugerido']),
      codigoPrerequisito: asString(json['codigo_prerequisito']) ?? '',
      nombrePrerequisito: asString(json['nombre_prerequisito']) ?? 'Prerrequisito',
      estadoPrerequisito: asString(json['estado_prerequisito']) ?? 'pendiente',
      tipoBloqueo: asString(json['tipo_bloqueo']) ?? 'prerrequisito_pendiente',
      notaPrerequisito: asDouble(json['nota_prerequisito']),
    );
  }
}

/// Fila de `unab.v_historial_detalle`.
class HistoryEntry {
  const HistoryEntry({
    required this.codigoCurso,
    required this.curso,
    required this.creditos,
    this.semestreSugerido,
    this.area,
    required this.periodo,
    this.nota,
    required this.estado,
    required this.intento,
  });

  final String codigoCurso;
  final String curso;
  final int creditos;
  final int? semestreSugerido;
  final String? area;
  final String periodo;
  final double? nota;
  final String estado;
  final int intento;

  bool get aprobado => estado == 'aprobado' || estado == 'homologado';

  String get estadoLabel {
    switch (estado) {
      case 'aprobado':
        return 'Aprobado';
      case 'homologado':
        return 'Homologado';
      case 'reprobado':
        return 'Reprobado';
      case 'en_curso':
        return 'En curso';
      case 'cancelado':
        return 'Cancelado';
      default:
        return estado;
    }
  }

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      codigoCurso: asString(json['codigo_curso']) ?? '',
      curso: asString(json['curso']) ?? 'Curso',
      creditos: asInt(json['creditos']) ?? 0,
      semestreSugerido: asInt(json['semestre_sugerido']),
      area: asString(json['area']),
      periodo: asString(json['periodo']) ?? '—',
      nota: asDouble(json['nota']),
      estado: asString(json['estado']) ?? 'en_curso',
      intento: asInt(json['intento']) ?? 1,
    );
  }
}
