/// Utilidades para leer JSON de forma tolerante.
///
/// n8n y Postgres pueden devolver números como `int`, `double` o `String`
/// según el driver y la versión. Estas funciones normalizan los tipos.
library;

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((dynamic key, dynamic item) => MapEntry(key.toString(), item));
  }
  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) return value;
  return const <dynamic>[];
}

String? asString(dynamic value) {
  if (value == null) return null;
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

double? asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

DateTime? asDate(dynamic value) {
  final String? text = asString(value);
  if (text == null) return null;
  return DateTime.tryParse(text);
}

bool asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String text = value.toLowerCase();
    return text == 'true' || text == '1' || text == 'si' || text == 'sí';
  }
  return false;
}
