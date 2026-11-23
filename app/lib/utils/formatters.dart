/// Formato de fechas y números en español (sin dependencias externas).
class Formatters {
  Formatters._();

  static const List<String> _months = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  static const List<String> _monthsShort = <String>[
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const List<String> _weekdays = <String>[
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  /// `20/11/2026`
  static String date(DateTime? value) {
    if (value == null) return '—';
    final String day = value.day.toString().padLeft(2, '0');
    final String month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  /// `20 de noviembre de 2026`
  static String longDate(DateTime? value) {
    if (value == null) return '—';
    return '${value.day} de ${_months[value.month - 1]} de ${value.year}';
  }

  /// `vie 20 nov`
  static String shortDate(DateTime? value) {
    if (value == null) return '—';
    final String weekday = _weekdays[value.weekday - 1].substring(0, 3);
    return '$weekday ${value.day} ${_monthsShort[value.month - 1]}';
  }

  /// `20 nov`
  static String dayMonth(DateTime? value) {
    if (value == null) return '—';
    return '${value.day} ${_monthsShort[value.month - 1]}';
  }

  /// `20`
  static String dayNumber(DateTime? value) {
    if (value == null) return '—';
    return value.day.toString().padLeft(2, '0');
  }

  /// `nov`
  static String monthShort(DateTime? value) {
    if (value == null) return '';
    return _monthsShort[value.month - 1];
  }

  /// `2026-2` a partir de un periodo tipo `2026-20` o `202620`.
  static String periodLabel(String? periodo) {
    if (periodo == null || periodo.isEmpty) return 'Periodo actual';
    return periodo;
  }

  /// Texto relativo para eventos del calendario.
  static String relativeDays(int? days) {
    if (days == null) return '';
    if (days < 0) {
      final int past = days.abs();
      return 'Hace $past día${past == 1 ? '' : 's'}';
    }
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Mañana';
    return 'En $days días';
  }

  /// Texto relativo para noticias publicadas.
  static String publishedAgo(int? days) {
    if (days == null) return '';
    if (days <= 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    return 'Hace $days días';
  }

  static String decimal(num? value, {int digits = 1}) {
    if (value == null) return '—';
    return value.toDouble().toStringAsFixed(digits);
  }

  static String percent(num? value) {
    if (value == null) return '—';
    return '${value.toDouble().toStringAsFixed(1)}%';
  }

  static String credits(num? value) {
    if (value == null) return '—';
    return value.toInt().toString();
  }

  static String integer(num? value) {
    if (value == null) return '—';
    return value.toInt().toString();
  }

  /// `hace 4 s`, `hace 2 min`
  static String latency(int? milliseconds) {
    if (milliseconds == null || milliseconds <= 0) return '';
    if (milliseconds < 1000) return '$milliseconds ms';
    final int seconds = (milliseconds / 1000).round();
    if (seconds < 60) return '${seconds}s';
    final int minutes = (seconds / 60).round();
    return '$minutes min';
  }
}
