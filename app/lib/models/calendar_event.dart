import '../utils/json_utils.dart';

/// Evento del calendario académico (`unab.v_calendario_proximo`).
class CalendarEvent {
  const CalendarEvent({
    this.id,
    this.periodo,
    required this.evento,
    this.categoria,
    this.fechaInicio,
    this.fechaFin,
    this.descripcion,
    this.diasFaltantes,
  });

  final int? id;
  final String? periodo;
  final String evento;
  final String? categoria;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? descripcion;
  final int? diasFaltantes;

  bool get hasRange {
    final DateTime? start = fechaInicio;
    final DateTime? end = fechaFin;
    if (start == null || end == null) return false;
    return end.difference(start).inDays > 0;
  }

  String get categoriaLabel {
    switch ((categoria ?? '').toLowerCase()) {
      case 'matricula':
        return 'Matrícula';
      case 'examenes':
        return 'Exámenes';
      case 'clases':
        return 'Clases';
      case 'pagos':
        return 'Pagos';
      case 'ceremonia':
        return 'Ceremonia';
      default:
        return 'General';
    }
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: asInt(json['id']),
      periodo: asString(json['periodo']),
      evento: asString(json['evento']) ?? 'Evento sin título',
      categoria: asString(json['categoria']),
      fechaInicio: asDate(json['fecha_inicio']),
      fechaFin: asDate(json['fecha_fin']),
      descripcion: asString(json['descripcion']),
      diasFaltantes: asInt(json['dias_faltantes']),
    );
  }
}
